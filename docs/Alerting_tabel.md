|Alert Level|Title|Purpose|Condition|
|-|-|--------|-------------|
|Info|InstanceScaleOut|노드 스케일 아웃 인지|클러스터 노드 수 증가 시 알람|클러스터 노드 수 증가시 알람|
||MoreThanHalfOfInstances|가용 가능한 추가 머신 절반 이하 사실 인지|AutoScalingGroup 의 생성 가능 노드 수 한계치 절반 초과시 알람|
||ImbalancedZone|가용영역 별 노드 수 불균형 인지|특정 가용영역 노드 수가 전체 가용영역 노드수의 20% 이하 시 알람|
|Warning|CrashedZone|다중 가용영역 보장을 위한 조치 필요|특정 가용영역에 생존해있는 노드 없을 때 알람|
||MasterDown|마스터 노드 HA 보장을 위한 조치 필요|마스터노드 다운 시 알람|
||MaximumInstances|오토스케일링 장애 대비를 위한 조치 필요|AutoScalingGroup 의 생성 가능 노드 수 한계치 도달 시 알람|
|Error|ScaleOutLimitations|신속한 서비스 레이턴시 증가 해결|AutoScalingGroup 의 생성 가능 노드 수 한계치 도달, 서비스 애플리케이션 Peding 상태 시 알람|


HTTP Request 로 알람


Pod Scheduler

