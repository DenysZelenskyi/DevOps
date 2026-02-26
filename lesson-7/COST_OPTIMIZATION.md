# Оптимизация затрат для уроков 8-9

## ✅ Сделанные изменения для минимизации затрат

### 1. Увеличен размер нод до t3.medium (ОБЯЗАТЕЛЬНО)
**Файл**: `modules/eks/variables.tf`
- **Было**: `t3.small` (2GB RAM) - $14.60/мес за ноду
- **Стало**: `t3.medium` (4GB RAM) - $29.20/мес за ноду
- **Причина**: Jenkins + Argo CD требуют минимум 3GB RAM. t3.small физически не может запустить оба приложения
- **Разница**: +$14.60/мес за ноду × 2 = **+$29.20/мес**

### 2. Использован NodePort вместо LoadBalancer
**Файлы**: 
- `modules/jenkins/values.yaml`
- `modules/argo_cd/values.yaml`

- **Было**: 2 LoadBalancer (Jenkins + Argo CD) = $45/мес
- **Стало**: NodePort (бесплатно)
- **Экономия**: **-$45/мес**

### 3. Один NAT Gateway (уже был оптимизирован)
**Файл**: `modules/vpc/vpc.tf`
- **Используется**: 1 NAT Gateway = $32.85/мес
- **Альтернатива**: 3 NAT Gateway (по одному на AZ) = $98.55/мес
- **Экономия**: **-$65.70/мес**

## Итоговые затраты

### Базовая конфигурация (текущая)
| Ресурс | Количество | Стоимость |
|--------|------------|-----------|
| EKS Control Plane | 1 | $73.00/мес |
| t3.medium nodes | 2 | $58.40/мес |
| NAT Gateway | 1 | $32.85/мес |
| EBS volumes (gp2) | ~40GB | $4.00/мес |
| ECR storage | ~1GB | $1.00/мес |
| **ИТОГО** | | **~$169/мес** |

### Предыдущая конфигурация (не работала)
| Ресурс | Количество | Стоимость |
|--------|------------|-----------|
| EKS Control Plane | 1 | $73.00/мес |
| t3.small nodes | 2 | $29.20/мес |
| LoadBalancers | 2 | $45.00/мес |
| NAT Gateway | 1 | $32.85/мес |
| EBS volumes | ~40GB | $4.00/мес |
| ECR storage | ~1GB | $1.00/мес |
| **ИТОГО** | | **~$185/мес** |

### ✅ Экономия: $16/мес при работающей конфигурации

## Доступ к сервисам с NodePort

### Jenkins
```bash
# Получить IP ноды
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')

# Получить NodePort
JENKINS_PORT=$(kubectl get svc jenkins -n jenkins -o jsonpath='{.spec.ports[0].nodePort}')

# Открыть Jenkins
echo "Jenkins: http://$NODE_IP:$JENKINS_PORT"

# Альтернатива: port-forward для локального доступа
kubectl port-forward -n jenkins svc/jenkins 8080:8080
# Открыть: http://localhost:8080
```

### Argo CD
```bash
# Получить NodePort
ARGOCD_PORT=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

# Открыть Argo CD
echo "Argo CD: http://$NODE_IP:$ARGOCD_PORT"

# Альтернатива: port-forward
kubectl port-forward -n argocd svc/argocd-server 8080:80
# Открыть: http://localhost:8080
```

## Дополнительные способы экономии (опционально)

### 1. Spot Instances (экономия ~70%)
Использовать EC2 Spot вместо On-Demand:
- **t3.medium On-Demand**: $29.20/мес
- **t3.medium Spot**: ~$8.76/мес
- **Экономия**: ~$41/мес на 2 нодах

⚠️ **Риск**: Spot instances могут быть отозваны AWS в любой момент

**Изменения** в `modules/eks/eks.tf`:
```hcl
resource "aws_eks_node_group" "main" {
  capacity_type = "SPOT"  # Добавить эту строку
  # ... остальное без изменений
}
```

### 2. Автоматическое выключение (экономия ~66%)
Выключать кластер в нерабочее время:
- **Работа**: Пн-Пт 9:00-18:00 (9 часов)
- **Выключен**: остальное время (15 часов + выходные)
- **Экономия**: ~$112/мес

Скрипт для автоматизации:
```bash
# Остановить ноды (сохранив кластер)
aws eks update-nodegroup-config \
  --cluster-name lesson-7-eks-cluster \
  --nodegroup-name lesson-7-eks-cluster-node-group \
  --scaling-config minSize=0,maxSize=0,desiredSize=0

# Запустить ноды
aws eks update-nodegroup-config \
  --cluster-name lesson-7-eks-cluster \
  --nodegroup-name lesson-7-eks-cluster-node-group \
  --scaling-config minSize=1,maxSize=3,desiredSize=2
```

### 3. Использовать t3a.medium (экономия ~10%)
AMD-процессоры дешевле:
- **t3.medium**: $29.20/мес
- **t3a.medium**: $26.28/мес
- **Экономия**: ~$6/мес на 2 нодах

**Изменения** в `modules/eks/variables.tf`:
```hcl
default = ["t3a.medium"]
```

### 4. Региональная экономия
Некоторые регионы дешевле us-east-1:
- **us-east-1**: 100% стоимость
- **us-east-2 (Ohio)**: ~95% стоимость
- **us-west-2 (Oregon)**: ~100% стоимость

Экономия незначительная, но каждая копейка считается.

### 5. Reserved Instances (долгосрочная экономия)
При использовании 1+ год:
- **1 год, частичная предоплата**: скидка ~40%
- **3 года, полная предоплата**: скидка ~60%

Для обучения не подходит.

## Рекомендуемая конфигурация для задания

### Минимальная работающая (текущая)
```
✅ 2x t3.medium nodes
✅ 1 NAT Gateway
✅ NodePort services
✅ EBS CSI Driver
≈ $169/мес
```

### С дополнительной экономией
```
✅ 2x t3a.medium Spot nodes
✅ 1 NAT Gateway
✅ NodePort services
✅ Автоматическое выключение по расписанию
≈ $35/мес (при работе 9 часов/день)
```

## Что НЕ стоит экономить

❌ **EKS Control Plane**: Нельзя выключить, $73/мес - фиксированная стоимость
❌ **EBS CSI Driver**: Необходим для persistent volumes
❌ **NAT Gateway**: Без него приватные ноды не смогут скачивать образы

## Проверка текущих затрат

```bash
# Использовать AWS Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=2026-02-01,End=2026-02-28 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=SERVICE

# Или через веб-консоль
# https://console.aws.amazon.com/cost-management/home#/dashboard
```

## Итоговая инструкция

1. ✅ **Применены изменения**:
   - t3.medium вместо t3.small
   - NodePort вместо LoadBalancer

2. 🔄 **Дождаться завершения** `terraform destroy`

3. 🚀 **Развернуть заново**:
   ```bash
   terraform apply -auto-approve
   ```

4. 🔧 **Настроить доступ** через port-forward

5. 📊 **Проверить затраты** через 2-3 дня в Cost Explorer

6. 🎓 **После сдачи задания** - обязательно выполнить `terraform destroy`
