# Быстрый старт для уроков 8-9

## ✅ Что изменено для минимизации затрат

1. **t3.medium вместо t3.small** - необходимо для Jenkins + Argo CD
2. **NodePort вместо LoadBalancer** - экономия $45/мес  
3. **1 NAT Gateway** - уже оптимизировано

**Итоговая стоимость: ~$169/мес** (было бы $185/мес с LoadBalancer)

## 🚀 Шаги для развертывания

### 1. Дождаться завершения terraform destroy

```bash
# Проверить статус (должно занять ~10-12 минут)
ps aux | grep terraform
```

### 2. Создать репозиторий для Helm charts

```bash
# На GitHub создать новый репозиторий: lesson-7-helm-charts

# Локально
cd ..
mkdir lesson-7-helm-charts
cd lesson-7-helm-charts
git init
git remote add origin https://github.com/YOUR_USERNAME/lesson-7-helm-charts.git

# Скопировать charts
cp -r ../lesson-7/charts .

# Первый коммит
git add .
git commit -m "Initial Helm charts"
git push -u origin main
```

### 3. Обновить переменные

В `lesson-7` директории создать `terraform.tfvars`:

```hcl
django_app_repo_url = "https://github.com/YOUR_USERNAME/lesson-7-helm-charts.git"
jenkins_admin_password = "YourSecurePassword123!"
```

### 4. Развернуть инфраструктуру

```bash
cd ../lesson-7

# Проверить изменения
terraform validate

# Развернуть (займет ~15-20 минут)
terraform apply -auto-approve
```

### 5. Настроить kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name lesson-7-eks-cluster

# Проверить
kubectl get nodes
kubectl get pods -n jenkins
kubectl get pods -n argocd
```

### 6. Получить доступ к Jenkins

```bash
# Port-forward (рекомендуется)
kubectl port-forward -n jenkins svc/jenkins 8080:8080

# В другом терминале получить пароль
kubectl get secret -n jenkins jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d

# Открыть: http://localhost:8080
# Логин: admin
# Пароль: (из команды выше)
```

### 7. Настроить Jenkins Credentials

В Jenkins UI → Manage Jenkins → Credentials:

**1. ECR Repository URL** (ID: `ecr-repository-url`)
```bash
# Получить URL
terraform output ecr_repository_url
```
- Type: Secret text
- Secret: (URL из команды выше)

**2. GitHub Token** (ID: `github-token`)
- Type: Username with password
- Username: Ваш GitHub username
- Password: GitHub Personal Access Token (Settings → Developer settings → PAT)

### 8. Создать Pipeline в Jenkins

1. New Item → "django-app-pipeline" → Pipeline
2. Pipeline section:
   - Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: `https://github.com/YOUR_USERNAME/lesson-7.git`
   - Branch: `*/lesson-8-9`
   - Script Path: `Jenkinsfile`
3. Save

### 9. Получить доступ к Argo CD

```bash
# Port-forward
kubectl port-forward -n argocd svc/argocd-server 8081:80

# Получить пароль
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Открыть: http://localhost:8081
# Логин: admin
# Пароль: (из команды выше)
```

### 10. Запустить Pipeline

1. В Jenkins → django-app-pipeline → Build Now
2. Наблюдать за процессом:
   - ✅ Checkout code
   - ✅ Build Docker image (Kaniko)
   - ✅ Push to ECR
   - ✅ Update Helm chart tag
3. В Argo CD смотреть auto-sync

## 📋 Проверка работы

```bash
# Jenkins pods
kubectl get pods -n jenkins
# Должно быть: jenkins-0 Running

# Argo CD pods
kubectl get pods -n argocd
# Должно быть: 6/6 Running

# Django application (после деплоя)
kubectl get pods
kubectl get svc

# Logs
kubectl logs -n jenkins jenkins-0 -f
```

## 🧹 Очистка после сдачи

```bash
# Удалить Helm releases
helm uninstall jenkins -n jenkins
helm uninstall argocd -n argocd
helm uninstall argocd-apps -n argocd

# Удалить инфраструктуру
terraform destroy -auto-approve
```

## 💰 Стоимость

- **Во время работы**: ~$169/мес (~$0.23/час)
- **После terraform destroy**: $0

**Совет**: Работать с кластером только когда нужно, удалять сразу после тестирования.

## 🔧 Troubleshooting

### Pods pending/not starting
```bash
kubectl describe pod POD_NAME -n NAMESPACE | grep -A 10 Events
```

### Jenkins logs
```bash
kubectl logs -n jenkins jenkins-0 -c jenkins
```

### Argo CD not syncing
```bash
kubectl logs -n argocd deployment/argocd-application-controller
```

### Cost check
```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-02-01,End=2026-02-28 \
  --granularity MONTHLY \
  --metrics UnblendedCost
```

## 📚 Дополнительно

Подробнее о дополнительной экономии: [COST_OPTIMIZATION.md](COST_OPTIMIZATION.md)
