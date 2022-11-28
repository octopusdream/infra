# 채널을 아래와 같이 분류하여, 얼럿 레벨에 맞게 대응 피로도 조절.

## Info: https://hooks.slack.com/services/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

- Instance down
- Instance ScaleOut

## Warning: https://hooks.slack.com/services/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

- #Instance max: scale out max value를 애초에 높게 잡으면 되지않나? 운영상의 문제로, 비용을 고려했을 때 맥스 값을 설정해야 한다고 판단. ASG 는 인스턴스 수를 선언하지 않는다.
ASG 가 늘릴 수 있는 node 수가 명시 되어있다.
결론: ASG max number 는 도달하기 힘든 높은 값을 주고, 이상이라고 판단할만한 기준치 노드 수를 선언하면 될듯하다.

- InstanceBusy: 인스턴스 수가 
- 특정 존에 워커 노드 부재
- Master Instance down
- Core component Ready or Networking

## Error: https://hooks.slack.com/services/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

- Instance max && cannot create pod(Resource Insufficient): 노드 
- Only one zone has worker node
- Master Quarom broken



Reference
- https://stackoverflow.com/questions/65595976/how-to-get-number-of-nodes-running-in-prometheus



