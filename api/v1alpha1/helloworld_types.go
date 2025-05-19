package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// HelloWorldSpec defines the desired state of HelloWorld
type HelloWorldSpec struct {
	// For this simple example, we might not need any specific fields.
	// You could add fields here later, e.g., Message string `json:"message,omitempty"`
	Size int32 `json:"size"` // We'll use this to ensure only one pod.
}

// HelloWorldStatus defines the observed state of HelloWorld
type HelloWorldStatus struct {
	// Conditions represent the latest available observations of an object's state
	// +operator-sdk:csv:customresourcedefinitions:type=status
	Conditions []metav1.Condition `json:"conditions,omitempty" patchStrategy:"merge" patchMergeKey:"type" protobuf:"bytes,1,rep,name=conditions"`
	PodName    string             `json:"podName,omitempty"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status

// HelloWorld is the Schema for the helloworlds API
type HelloWorld struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   HelloWorldSpec   `json:"spec,omitempty"`
	Status HelloWorldStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// HelloWorldList contains a list of HelloWorld
type HelloWorldList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []HelloWorld `json:"items"`
}

func init() {
	SchemeBuilder.Register(&HelloWorld{}, &HelloWorldList{})
}
