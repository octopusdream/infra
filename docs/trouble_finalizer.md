## Goal
>
생성한 pv, pvc를 kubectl delete 명령어로 삭제가 안되는 원인을 파악하고 해결한다.

```
k delete -f prometheus-server-volume.yaml

⚡ root@master  ~/prometheus  k get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS        CLAIM                       STORAGECLASS   REASON   AGE
prometheus-server   10Gi       RWX            Retain           Terminating   default/prometheus-server                           131m
```
>
delete 해도 STATUS == Terminating 상태에서 지워지지 않는다.
kubectl delete pv (pv name) --grace-period=0 --force 명령어로도 삭제가 불가능.

[쿠버네티스 공식 문서](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#finalizers) 에 따르면 삭제가 불가능 한 이유는 Finalizer 때문이다. 

## ✌삭제하는 법

```
kubectl edit pv
kubectl edit pvc
```
![](https://velog.velcdn.com/images/hyunshoon/post/d5bef399-1ca2-4903-8f40-2d113f116ef7/image.png)

위 finalizer를 삭제해준다. 이미 Terminating 상태이므로 수정만 해주면 pv, pvc는 삭제된다.

## 🤷‍♂️Finalizer?

Finalizer를 지워주면 삭제된다는 것을 알았다. 이제 그 원리를 알아보자.

### Summary

>
파이널라이저는 리소스가 삭제되기 전 충족되야할 조건이다. 
>
Finalized 된 리소스의 삭제 명령이 떨어지면, 조건이 충족될 때 까지 리소스는 변경사항에 대해 잠긴다.
>
파이널라이저는 컨트롤플레인이나 Operator와 같은 커스텀 컨트롤러에 시그널을 보내는데 사용된다. 시그널을 보내 완전히 리소스를 제거하기전에 해당 리소스를 정리하는데 사용하기 위해서.

### 공식 문서 설명

>
파이널라이저는 쿠버네티스가 **오브젝트를 완전히 삭제하기 이전**, 삭제 표시를 위해 **특정 조건이 충족될 때까지 대기**하도록 알려주기 위한 네임스페이스에 속한 키(namespaced key)이다. **파이널라이저는 삭제 완료된 오브젝트가 소유한 리소스를 정리하기 위해 컨트롤러에게 알린다.**
>
파이널라이저를 가진 특정한 오브젝트를 쿠버네티스가 삭제하도록 지시할 때, 쿠버네티스 API는 .metadata.delationTimestamp을 덧붙여 삭제하도록 오브젝트에 표시하며, 202 상태코드(HTTP "Accepted")을 리턴한다. **대상 오브젝트가 Terminating 상태를 유지하는 동안** 컨트롤 플레인 또는 다른 컴포넌트는 하나의 파이널라이저에서 정의한 작업을 수행한다. 정의된 작업이 완료 후에, 그 컨트롤러는 대상 오브젝트로부터 연관된 파이널라이저을 삭제한다. metadata.finalizers 필드가 비어 있을 때, 쿠버네티스는 삭제가 완료된 것으로 간주하고 오브젝트를 삭제한다.
>
파이널라이저가 리소스들의 가비지 컬렉션을 제어하도록 사용할 수 있다. 예를 들어, 하나의 파이널라이저를 컨트롤러가 대상 리소소를 삭제하기 전에 연관된 리소스들 또는 인프라를 정리하도록 정의할 수 있다.
>
파이널라이저(Finalizer)를 사용하면 리소스를 삭제하기 전 특정 정리 작업을 수행하도록 컨트롤러(Controller)에 경고하여 리소스의 가비지(Garbage) 수집을 제어할 수 있다.
>
파이널라이저는 보통 실행할 코드를 지정하지 않는다. 대신 파이널라이저는 일반적으로 어노테이션과 비슷하게 특정 리소스에 대한 키들의 목록이다. 일부 파이널라이저는 쿠버네티스가 자동으로 지정하지만, 사용자가 직접 지정할 수도 있다.


#### 결론적으로 pv, pvc 말고도 delete로 삭제한 pod 가 Terminating 상태에 갇혀 있다면 finalizer를 삭제해보자.

Reference
- https://kubernetes.io/ko/docs/concepts/overview/working-with-objects/finalizers/
- https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#finalizers
- https://kubebyexample.com/learning-paths/operator-framework/kubernetes-api-fundamentals/finalizers