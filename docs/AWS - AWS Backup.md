### AWS Backup 옵션

EFS 파일 시스템을 백업하여 데이터를 보호하는 데 사용할 수 있는 옵션은 2가지가 있다.

- [AWS Backup 서비스](https://docs.aws.amazon.com/ko_kr/efs/latest/ug/awsbackup.html)

> AWS Backup 은 간편하고 효율적인 방법으로 Amazon EFS 파일 시스템을 백업할 수 있다. AWS Backup은 향상된 보고 및 감사 기능을 제공하는 동시에 백업 생성, 마이그레이션, 복원 및 삭제를 간소화하도록 설계된 통합 백업 서비스이다.

- [EFS-EFS 백업 솔루션](https://aws.amazon.com/ko/solutions/implementations/efs-to-efs-backup-solution/)

> EFS-EFS 백업 솔루션은 모든 Amazon EFS 파일 시스템에 적합한 솔루션이다. AWS CloudFormation를 실행, 구성, 실행하는 템플릿 AWS 서비스이 솔루션을 배포하는 데 필요하다.

---

### AWS Backup 사용 이유

완전관리형 백업 서비스인 AWS Backup을 사용하여 Amazon EFS 파일 시스템에 대한 백업을 중앙에서 관리할 수 있다. AWS는 이 솔루션을 사용하기 전에 AWS Backup이 사용자의 특정 사용 사례에 맞는지 평가해 볼 것을 권장한다. AWS는 의도하지 않은 사용자 변경 또는 삭제로부터의 복구를 위해 AWS Backup을 사용하여 Amazon EFS를 위한 백업 솔루션을 구현할 것을 권장한다. 리전별 최신 Amazon EFS 가용성은 [리전별 제품 서비스 표](https://aws.amazon.com/ko/about-aws/global-infrastructure/regional-product-services/)를 참조한다.

> AWS 에서는 해당 리전에서 AWS Backup을 사용할 수 없다면, 이 EFS-to-EFS Backup 솔루션을 사용할 것을 권장한다. 따라서 우리가 프로젝트를 진행하고 있는 리전에서는 AWS Backup 서비스를 사용할 수 있으므로 AWS Backup 을 사용해 EFS 파일 시스템을 백업할 것이다.

---

### EFS Backup

[Amazon EFS Backup and Restore using AWS Backup | Amazon Web Services](https://aws.amazon.com/ko/getting-started/hands-on/amazon-efs-backup-and-restore-using-aws-backup/)

AWS Backup 은 여러 AWs 서비스의 백업을 간편하게 도와주는 서비스이다. AWS Backup 을 사용하면 AWS 서비스에 대한 데이터 보호를 중앙 집중화하고 자동화할 수 있다. AWS Backup 은 정책을 기반으로 대규모 데이터 보호를 간편하고 비용 효율적으로 수행할 수 있는 완전관리형 서비스이다.

> 지원하는 서비스
> 
> - Amazon FSx
> - Amazon EFS
> - Amazon DynamoDB
> - Amazon EC2
> - Windows VSS (Volume Shadow Copy Service) on EC2
> - Amazon EBS
> - Amazon RDS
> - Amazon Aurora
> - AWS Storage Gateway (Volume Gateway)

---

### terraform

```bash
resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.efs.id

  backup_policy {
    status = "ENABLED"
  }
}
```

**`Status`** 파일 시스템에 대한 백업 정책 상태를 설정합니다 .

- **`ENABLED` :** 파일 시스템에 대한 자동 백업을 켭니다.
- **`DISABLED`** : 파일 시스템에 대한 자동 백업을 끕니다


