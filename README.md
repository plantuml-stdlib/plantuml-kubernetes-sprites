# Kubernetes sprite resources for PlantUML

These sprites have been generated using the PlantUML `encodesprite` command. [http://plantuml.com/sprite](http://plantuml.com/sprite)

The source of the images is the kubernetes-icons repository at [https://github.com/octo-technology/kubernetes-icons](https://github.com/octo-technology/kubernetes-icons)

## Example

```uml
@startuml
!include ../resource/k8s-sprites-unlabeled-25pct.iuml
package "Infrastructure" {
  component "<$master>\nmaster" as master
  component "<$etcd>\netcd" as etcd
  component "<$node>\nnode" as node
}
```

## Unlabeled - 25%

![Unlabeled 25% kubernetes k8s plantuml sprite icons](/out/k8s-sprites-unlabeled-25pct-demo.png?raw=true)

## Labeled - 25%

![Labeled 25% kubernetes k8s plantuml sprite icons](/out/k8s-sprites-labeled-25pct-demo.png?raw=true)

