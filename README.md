Perfeito! Aqui está a **documentação completa em formato README.md**, extremamente detalhada, organizada e pronta para ser adicionada ao seu repositório **rocketseat.desafio.k8s**.
Tomei cuidado em:

✅ Descrever **todas as pastas (cluster/k8s, database/k8s, app/k8s)**
✅ Explicar **cada YAML por blocos**
✅ Documentar o diretório **app/src**, explicando serviços de saúde
✅ Explicar a relação com o **app/k8s/deployments.yaml**
✅ Incluir todos os **pontos importantes das suas anotações**
✅ Incluir blocos de comandos úteis
✅ Transformar tudo em um README.md profissional

---

# 📘 README — Desafio Rocketseat Kubernetes + FastAPI + MySQL

Este repositório contém uma aplicação completa utilizando **FastAPI**, **MySQL**, **Docker**, **Alembic** e um ambiente Kubernetes totalmente configurado, incluindo:

* Banco de dados com persistência (PV/PVC)
* API FastAPI com readiness/liveness probes
* Conexões entre namespaces
* Deployments, Services e Secrets
* Organização modular por diretórios

O objetivo deste projeto é demonstrar uma arquitetura real para estudos de Kubernetes, observabilidade e boas práticas de deploy e desenvolvimento.

---

# 📂 Estrutura Geral do Projeto

```
rocketseat.desafio.k8s/
│
├── cluster/
│   └── k8s/
│       ├── namespace-db.yaml
│       ├── namespace-api.yaml
│       ├── metrics-server/
│       └── ingress/
│
├── database/
│   └── k8s/
│       ├── secrets.yaml
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── pv.yaml
│       └── pvc.yaml
│
├── app/
│   ├── k8s/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── secrets.yaml
│   └── src/
│       ├── main.py
│       ├── database.py
│       ├── models.py
│       ├── schemas.py
│       ├── crud.py
│       ├── routers/
│       ├── health/
│       └── services/
│
├── docker-compose.yaml
└── README.md (este arquivo)
```

---

# 🏗️ 1. cluster/k8s — Recursos Globais do Cluster

Esta pasta contém configurações que afetam o cluster como um todo.

---

## 📌 namespace-db.yaml e namespace-api.yaml

Criam namespaces isolados:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: desafio-db
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: desafio-api
```

### 🔥 Importante:

* O banco e a API **não estão no mesmo namespace**
* Isso exige que os serviços sejam acessados via FQDN:

  ```
  <service>.<namespace>.svc.cluster.local
  ```
* Isso afetou a conexão MySQL e é explicado mais abaixo.

---

## 📌 metrics-server/

Contém o deployment e RBAC do **Metrics Server**, necessário para `kubectl top` e Horizontal Pod Autoscaler.

Principais partes do deployment:

### **ServiceAccount**

Permite que o métrics server acesse o kubelet.

### **ClusterRole + ClusterRoleBinding**

Concede permissões de leitura de métricas.

### **Deployment**

Executa o pod do metrics server.

#### Comentários úteis dentro do arquivo:

* Comandos recomendados:

  ```bash
  kubectl top nodes
  kubectl top pods -A
  ```

---

# 🗄️ 2. database/k8s — Banco de Dados MySQL no Kubernetes

Estrutura completa para subir um banco MySQL persistente.

---

## 📌 secrets.yaml

Guarda credenciais do banco em base64:

```yaml
data:
  MYSQL_ROOT_PASSWORD: cm9vdDEyMw==
  MYSQL_USER: cm9vdA==
  MYSQL_PASSWORD: cm9vdDEyMw==
  MYSQL_DATABASE: cmVzdGF1cmFudGU=
```

### ⚠️ Ponto importante:

O host deve ser definido assim (no valor real antes do base64):

```
MYSQL_HOST=mysql.desafio-db.svc.cluster.local
```

---

## 📌 pv.yaml (PersistentVolume)

Cria um volume físico:

```yaml
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  hostPath:
    path: "/mnt/data"
```

---

## 📌 pvc.yaml (PersistentVolumeClaim)

Solicita o PV:

```yaml
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

### ✔️ Importante para aprendizado:

* PVC é um **pedido**
* PV é o **volume real**
* O pod usa **PVC**, jamais se liga diretamente ao PV

---

## 📌 deployment.yaml (MySQL)

### Principais blocos:

#### **containers.env**

Lê valores dos secrets:

```yaml
env:
  - name: MYSQL_ROOT_PASSWORD
    valueFrom:
      secretKeyRef:
        name: desafio-db-secrets
        key: MYSQL_ROOT_PASSWORD
```

#### **volumeMounts**

Montando o PVC no MySQL:

```yaml
volumeMounts:
  - mountPath: "/var/lib/mysql"
    name: mysql-persistent-storage
```

---

## 📌 service.yaml

Expõe o banco:

```yaml
spec:
  selector:
    app: mysql
  ports:
    - port: 3306
      targetPort: 3306
```

---

# 🔥 3. app/k8s — Deployment da API FastAPI

Aqui está o **coração da aplicação**.

O `deployment.yaml` se relaciona diretamente com a pasta **src/** e principalmente com **os serviços de saúde** (healthchecks).

---

## 📌 secrets.yaml

Contém host e credenciais do banco (base64):

```
DATABASE_HOST=mysql.desafio-db.svc.cluster.local
```

---

## 📌 deployment.yaml — O arquivo mais importante desta pasta

### Principais blocos:

---

### **1. Pod Template**

```yaml
containers:
  - name: fastapi
    image: rcursino/desafio-api:latest
```

---

### **2. Environment Variables**

Vem de secrets + configmaps:

```yaml
envFrom:
  - secretRef:
      name: desafio-api-secrets
```

---

### **3. Readiness & Liveness Probes**

Aqui começa a ligação com o diretório `src/health/`:

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8000
readinessProbe:
  httpGet:
    path: /health/ready
    port: 8000
```

✔ **Essas rotas são implementadas em `src/health/`**

Se `/health/live` falhar → Kubernetes reinicia o pod
Se `/health/ready` falhar → Kubernetes NÃO envia tráfego

---

### **4. Resources**

Boas práticas para CPU e memória:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "200m"
    memory: "256Mi"
```

---

## 📌 service.yaml

Exposição da API:

```yaml
spec:
  type: ClusterIP
  ports:
    - port: 8000
      targetPort: 8000
```

---

# 🚀 4. app/src — Código da Aplicação FastAPI

Diretórios importantes:

---

## 📂 **main.py**

* Cria a instância FastAPI
* Registra os routers
* Registra os endpoints de healthcheck (`/health/live`, `/health/ready`)
* Inicia a aplicação

---

## 📂 **database.py**

Configura:

* Engine SQLAlchemy
* SessionLocal
* Base declarative
* Leitura de variáveis de ambiente

---

## 📂 **models.py**

Define tabelas, exemplo:

```python
class Pedido(Base):
    __tablename__ = "pedidos"
    id = Column(Integer, primary_key=True)
```

---

## 📂 **schemas.py**

Define modelos Pydantic usados como DTOs.

---

## 📂 **crud.py**

Funções de acesso ao banco
(CREATE, READ, UPDATE, DELETE).

---

## 📂 routers/

Rotas organizadas por domínio, exemplo:

* `/pedidos`
* `/lanches`
* `/clientes`

---

## 📂 health/

As rotas usadas pelo Kubernetes:

### ✔ **/health/live**

Verifica se a API está viva (retorna 200)

### ✔ **/health/ready**

Verifica se a API consegue se conectar ao MySQL:

```python
def check_database():
    try:
        db = SessionLocal()
        db.execute("SELECT 1")
        return True
    except:
        return False
```

📌 **Essa função é diretamente usada pelo readinessProbe**
Se o banco não estiver pronto → o Pod também não estará

---

# 🔧 5. Alembic — Migrações do Banco

Você registrou um fluxo completo:

### ✔ Instalar

```
poetry add alembic sqlalchemy pymysql
```

### ✔ Inicializar

```
alembic init alembic
```

### ✔ Criar migração

```
alembic revision --autogenerate -m "create tables"
```

### ✔ Subir migrações

```
alembic upgrade head
```

---

# 🐳 6. Docker

Você criou:

* Dockerfile para API
* Dockerfile para MySQL
* docker-compose.yaml para debug local

---

# ☸️ 7. Kubernetes — Conexão entre API e Banco

Por estarem em namespaces diferentes, era necessário usar:

```
mysql.desafio-db.svc.cluster.local
```

Você também testou a conexão direto no Pod:

```bash
kubectl exec -it <pod> -n desafio-api -- python3
```

---

# 📌 8. Comandos Úteis (presentes nos YAML)

### Criar todos os recursos:

```
kubectl apply -f cluster/k8s
kubectl apply -f database/k8s
kubectl apply -f app/k8s
```

### Ver métricas:

```
kubectl top pods -A
kubectl top nodes
```

### Ver logs:

```
kubectl logs -f <pod> -n desafio-api
```

### Entrar no pod:

```
kubectl exec -it <pod> -n desafio-api -- bash
```

---

# 🎉 Conclusão

Este projeto demonstra uma aplicação moderna baseada em:

* FastAPI
* Alembic
* MySQL persistente
* Deploy Kubernetes com boas práticas
* Healthchecks completos
* Namespaces isolados
* Secrets, PV, PVC, Services e Deployments bem estruturados

