package controller

import (
	"context"
	"fmt"

	appsv1alpha1 "github.com/ashwindasr/helloworld-operator/api/v1alpha1" // Adjust to your module path
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"
)

// HelloWorldReconciler reconciles a HelloWorld object
type HelloWorldReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

//+kubebuilder:rbac:groups=apps.example.com,resources=helloworlds,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=apps.example.com,resources=helloworlds/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=apps.example.com,resources=helloworlds/finalizers,verbs=update
//+kubebuilder:rbac:groups=core,resources=pods,verbs=get;list;watch;create;update;patch;delete

func (r *HelloWorldReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)
	logger.Info("Reconciling HelloWorld")

	// Fetch the HelloWorld instance
	helloWorldInstance := &appsv1alpha1.HelloWorld{}
	err := r.Get(ctx, req.NamespacedName, helloWorldInstance)
	if err != nil {
		if errors.IsNotFound(err) {
			// Request object not found, could have been deleted after reconcile request.
			// Owned objects are automatically garbage collected. For additional cleanup logic use finalizers.
			// Return and don't requeue
			logger.Info("HelloWorld resource not found. Ignoring since object must be deleted")
			return ctrl.Result{}, nil
		}
		// Error reading the object - requeue the request.
		logger.Error(err, "Failed to get HelloWorld")
		return ctrl.Result{}, err
	}

	// Define the desired Pod
	desiredPod := r.podForHelloWorld(helloWorldInstance)

	// Check if this Pod already exists
	foundPod := &corev1.Pod{}
	err = r.Get(ctx, types.NamespacedName{Name: desiredPod.Name, Namespace: desiredPod.Namespace}, foundPod)
	if err != nil && errors.IsNotFound(err) {
		// Define a new Pod object
		logger.Info("Creating a new Pod", "Pod.Namespace", desiredPod.Namespace, "Pod.Name", desiredPod.Name)
		err = r.Create(ctx, desiredPod)
		if err != nil {
			logger.Error(err, "Failed to create new Pod", "Pod.Namespace", desiredPod.Namespace, "Pod.Name", desiredPod.Name)
			return ctrl.Result{}, err
		}
		// Pod created successfully - update status and requeue
		helloWorldInstance.Status.PodName = desiredPod.Name
		err = r.Status().Update(ctx, helloWorldInstance)
		if err != nil {
			logger.Error(err, "Failed to update HelloWorld status")
			return ctrl.Result{}, err
		}
		return ctrl.Result{Requeue: true}, nil
	} else if err != nil {
		logger.Error(err, "Failed to get Pod")
		return ctrl.Result{}, err
	}

	// If the pod is found, ensure it's what we expect (simplistic check here, could be more robust)
	// For this example, we are not checking for multiple pods if spec.size > 1,
	// but focusing on ensuring *one* pod as per the initial request.
	// A more robust check would involve listing pods with labels and ensuring count.

	logger.Info("Pod already exists", "Pod.Namespace", foundPod.Namespace, "Pod.Name", foundPod.Name)

	// Update status if it's not already set (or to reflect current state)
	if helloWorldInstance.Status.PodName != foundPod.Name {
		helloWorldInstance.Status.PodName = foundPod.Name
		err = r.Status().Update(ctx, helloWorldInstance)
		if err != nil {
			logger.Error(err, "Failed to update HelloWorld status after finding pod")
			return ctrl.Result{}, err
		}
	}

	return ctrl.Result{}, nil
}

// podForHelloWorld returns a HelloWorld Pod object
func (r *HelloWorldReconciler) podForHelloWorld(hw *appsv1alpha1.HelloWorld) *corev1.Pod {
	labels := labelsForHelloWorld(hw.Name)
	podName := fmt.Sprintf("%s-pod", hw.Name)

	pod := &corev1.Pod{
		ObjectMeta: metav1.ObjectMeta{
			Name:      podName,
			Namespace: hw.Namespace,
			Labels:    labels,
		},
		Spec: corev1.PodSpec{
			Containers: []corev1.Container{{
				Image:   "busybox:latest", // Using busybox for simplicity
				Name:    "helloworld",
				Command: []string{"sh", "-c", "echo 'Hello World from my very own operator! Instance: " + hw.Name + "' && sleep 3600"},
			}},
			RestartPolicy: corev1.RestartPolicyOnFailure, // Or Always, Never, depending on desired behavior
		},
	}
	// Set HelloWorld instance as the owner and controller
	ctrl.SetControllerReference(hw, pod, r.Scheme)
	return pod
}

// labelsForHelloWorld returns the labels for selecting the resources
// belonging to the given HelloWorld CR name.
func labelsForHelloWorld(name string) map[string]string {
	return map[string]string{"app.kubernetes.io/name": "HelloWorldApp",
		"app.kubernetes.io/instance":   name,
		"app.kubernetes.io/part-of":    "helloworld-operator",
		"app.kubernetes.io/created-by": "controller-manager",
	}
}

// SetupWithManager sets up the controller with the Manager.
func (r *HelloWorldReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&appsv1alpha1.HelloWorld{}).
		Owns(&corev1.Pod{}). // This tells the controller to watch Pods created by HelloWorld CRs
		Complete(r)
}
