## 1. CI/CD
CI/CD는 소프트웨어 개발 과정에서 **지속적인 통합**과 **지속적인 배포**를 자동화하는 방식이다. 이를 통해 개발과 배포 프로세스를 효율적이고 안정적으로 관리할 수 있다.

### 1) CI (Continuous Integration)
CI/CD의 "CI"는 개발자를 위한 자동화 프로세스인 지속적인 통합(Continuous Integration)을 의미한다. 코드 변경 사항을 자주 통합하고 자동화된 방식으로 테스트하는 것이다.

### 2) CD (Continuous Deployment)

Continuous Delivery는 개발된 소프트웨어를 언제든지 배포할 수 있는 상태로 유지하는 것을 의미한다. Continuous Deployment는 자동으로 프로덕션 환경에 배포까지 하는 것을 의미한다.

CI/CD를 사용하면 개발 과정이 더 빨라지고, 버그도 줄일 수 있다. 코드를 작성하고, 테스트하고, 배포하는 모든 과정을 자동화하여 개발자가 더 중요한 일에 집중할 수 있도록 한다. 

> 코드 작성 -> CI -> CD -> 배포

---

## 2. GitHub Actions

GitHub에서 제공하는 자동화 도구로, 코드 저장소에서 직접 워크플로우를 만들고 실행할 수 있도록 한다. 코드를 push하거나 pull request를 생성할 때마다 자동으로 빌드, 테스트, 배포 등의 작업을 수행할 수 있다.

### 1) workflow
- 자동화된 전체 프로세스 
- YAML 파일로 정의
- 저장소의 .github/workflows 디렉토리에 저장

### 2) Event
- 워크플로우를 트리거하는 특정 활동이나 규칙
- ex) push, pull request, 이슈 생성 등

### 3) Job
- 같은 러너에서 실행되는 여러 스텝의 집합
- 하나의 워크플로우는 여러 개의 잡으로 구성될 수 있음

### 4) Step
- 명령어를 실행하거나 액션을 사용하는 개별 작업
- 각 잡은 여러 개의 스텝으로 구성됨

### 5) Action
- 자주 반복되는 작업을 위한 재사용 가능한 유닛

## 3. GitHub Actions를 이용한 CI 파이프라인 구축
### 0) 구축 환경 세팅

![](https://velog.velcdn.com/images/icandooooo/post/907c8823-0760-4cc9-addf-78eac0d6a013/image.png)

```
scp -i ./project-key.pem ./food.tar ec2-user@43.203.42.254:/home/ec2-user/
```

![](https://velog.velcdn.com/images/icandooooo/post/2feca930-7ee9-448d-85ab-626b0e7be640/image.png)

CI 파이프라인 구축에 앞서 scp 명령어를 이용해 food.tar 파일을 EC2 인스턴스에 넣어 주었다.

```
[ec2-user@ip-10-0-4-193 ~]$ mkdir github-action-test
[ec2-user@ip-10-0-4-193 ~]$ cd github-action-test/
[ec2-user@ip-10-0-4-193 github-action-test]$ mkdir -p .github/workflows
[ec2-user@ip-10-0-4-193 github-action-test]$ sudo dnf install git
[ec2-user@ip-10-0-4-193 github-action-test]$ git clone https://github.com/F1T4-HOTSUN/github-actions-test.git
[ec2-user@ip-10-0-4-193 github-action-test]$ cd github-actions-test/
[ec2-user@ip-10-0-4-193 github-actions-test]$ tar xvf ~/food.tar -C ./
[ec2-user@ip-10-0-4-193 github-actions-test]$ mkdir -p .github/workflows
```
github-action-test 디렉터리를 생성하고 .github/workflows 디렉터리를 생성한 뒤 GitHub Repository를 Clone했다. food.tar의 압축도 해제했다.

```
[ec2-user@ip-10-0-4-193 github-actions-test]$ git add .
[ec2-user@ip-10-0-4-193 github-actions-test]$ git commit -m "add food.tar"
[ec2-user@ip-10-0-4-193 github-actions-test]$ git push origin main
```
Github에 food.tar를 Push했다.

```
sudo dnf install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
docker --version
```

EC2 인스턴스에 Docker를 설치했다.

### 1) Git Secret 설정
![](https://velog.velcdn.com/images/icandooooo/post/e9e2755d-a0f5-4dd5-b3e9-48eeaa0d8fc6/image.png)

먼저 gthub-actions-test Repository를 생성했다.

![](https://velog.velcdn.com/images/icandooooo/post/e080ee4e-d48c-4647-978a-d1c8e6edcfec/image.png)

[Git Repository - Settings - Secrets and variables - Actions] 에서 GitHub Actions에 필요한 환경변수를 설정할 수 있다. 정보를 보호하기 위해 환경 변수는 Secret에 Key-Value 형태로 등록한다. Docker Hub의 Username과 Password를 생성했다.

- 환경 변수 등록
  - Secret의 이름(Key)과 값 입력
  - Secret 등록 후 Value 값 확인 불가

=> 이렇게 등록된 Secret은 GitHub Actions 워크플로우에서 참조 및 민감한 정보가 노출되지 않도록 보호

### 2) DockerFile 작성
![](https://velog.velcdn.com/images/icandooooo/post/44379316-699b-4e70-88ed-26464be8fb42/image.png)

먼저 Docker Hub에서 새로운 Repository를 생성했다.

```
[ec2-user@ip-10-0-4-193 github-actions-test]$ vi Dockerfile

# Base image (Nginx)
FROM nginx:latest

# 작업 디렉토리 설정
WORKDIR /usr/share/nginx/html

# 현재 디렉토리에서 파일들을 컨테이너의 Nginx HTML 디렉토리로 복사
COPY ./assets /usr/share/nginx/html/assets
COPY ./vendors /usr/share/nginx/html/vendors
COPY ./index.html /usr/share/nginx/html/index.html

# 포트 노출
EXPOSE 80

```
GitHub Actions를 통해 Docker Image를 만들 DockerFile을 작성한다.

이 Dockerfile을 작성한 후, 해당 디렉토리에서 docker build 명령어를 실행하면 Docker 이미지가 빌드되며, 이미지가 실행되면 Nginx 서버가 위의 파일들을 제공한다.

```
[ec2-user@ip-10-0-4-193 github-actions-test]$ sudo docker build -t github-action-test .
[ec2-user@ip-10-0-4-193 github-actions-test]$ sudo docker run -d -p 80:80 github-action-test
```
docker build와 docker run 명령어를 이용해 Docker 이미지를 빌드하고 실행했다. 로컬에서 Docker 이미지를 테스트하는 과정으로, Docker Hub에 이미지를 푸시하지 않으며 현재 인스턴스에서만 실행된다.
- docker build -t github-action-test .
  - 현재 디렉토리(.)에 있는 Dockerfile을 참조해 Docker 이미지 빌드
  - github-action-test라는 이미지 이름 사용
  
- docker run -d -p 80:80 github-action-test
  - 앞서 빌드된 Docker 이미지 실행
  - -d : 백그라운드에서 실행 (Detached 모드)
  - -p 80:80 : 호스트의 80번 포트를 컨테이너의 80번 포트와 매핑하는 옵션
  - EC2 인스턴스의 public ip주소를 이용해 http://ec2-public-ip:80으로 접근 가능

![](https://velog.velcdn.com/images/icandooooo/post/99a4621d-70ae-46a5-b07a-5c6cb34c4391/image.png)

EC2 인스턴스의 80번 포트가 Nginx 서버에 연결되어 food.tar에서 추출된 파일들을 웹에서 제공할 수 있게 되었다.

![](https://velog.velcdn.com/images/icandooooo/post/77771345-ab2a-468a-b54c-1c9ddc609ae3/image.png)

docker images 명령어를 이용해 생성한 이미지를 확인할 수 있다.

```
git add .
git status
git commit -m "add Dockerfile"
git push origin main
```

Dockerfile을 GitHub에 Push했다.

```
[ec2-user@ip-10-0-4-193 github-actions-test]$ docker login

[ec2-user@ip-10-0-4-193 github-actions-test]$ sudo docker tag github-action-test:latest mjtwinsbbc/github-action-test:latest
```
Docker Hub에 업로드하기 위해 로컬 이미지 이름을 Docker Hub 레포지토리 이름에 맞춰 수정했다.

```
[ec2-user@ip-10-0-4-193 github-actions-test]$ sudo docker push mjtwinsbbc/github-action-test:latest
```

![](https://velog.velcdn.com/images/icandooooo/post/74731031-6014-4009-9f00-ce9a806b5cac/image.png)

Docker Hub에 성공적으로 Push했다.

> Docker Hub에 Push가 안 되는 문제가 발생했는데, docker logout 후 다시 docker login하니 해결되었다.

### 3) Kubernetes File 작성

#### namespace.yaml

```
[ec2-user@ip-10-0-4-193 github-actions-test]$ mkdir kubernetes && cd $_

vi namespace.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: ns-github-actions-test
```

namespace.yaml 작성

```
[ec2-user@ip-10-0-4-193 kubernetes]$ kubectl apply -f namespace.yaml 
```

ns-github-actions-test 네임스페이스를 생성했다.

kubectl get namespaces 명령어를 사용해 확인할 수 있다.

#### deployment.yaml

```
[ec2-user@ip-10-0-4-193 kubernetes]$ vi deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: food-app
  namespace: ns-github-actions-test  # 네임스페이스 지정
spec:
  replicas: 2
  selector:
    matchLabels:
      app: food-app
  template:
    metadata:
      labels:
        app: food-app
    spec:
      containers:
      - name: food-app
        image: mjtwinsbbc/github-action-test:latest  # 이미지 이름
        ports:
        - containerPort: 80
```

deployment.yaml 작성(애플리케이션 배포)
이 파일은 mjtwinsbbc/github-action-test:latest 이미지를 사용하는 Deployment 정의다.

- metadata.namespace : 이 Deployment가 ns-github-actions-test 네임스페이스에 배치됨
- spec.replicas: 2 : Pod 2개를 생성하여 고가용성 보장
- containers : 컨테이너 정의
  - name : 컨테이너 이름
  - image : Docker Hub에 있는 이미지 가져와 사용
- containerPort:80 : 컨테이너가 사용하는 포트

```
kubectl apply -f deployment.yaml
```

Deployment 배포

#### service.yaml

```
[ec2-user@ip-10-0-4-193 kubernetes]$ vi service.yaml

apiVersion: v1
kind: Service
metadata:
  name: food-service
  namespace: ns-github-actions-test  # 네임스페이스 지정
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"  # NLB를 사용
    service.beta.kubernetes.io/aws-load-balancer-internal: "false"  # External 로드밸런서로 설정
spec:
  selector:
    app: food-app  # Deployment와 연결된 Pod을 선택
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: LoadBalancer  # 외부에서 접근할 수 있도록 설정
```

service.yaml 작성
Kubernetes에서 LoadBalancer 서비스를 생성해 외부에서 접근할 수 있도록 설정하는 파일이다.

>annotations 부분을 작성하지 않았을 때 Internal NLB가 생성되어 curl 명령어로 접근하는 것은 가능했지만 웹 브라우저에서 로드밸런서로 접근되지 않았다. Internet-facing 로드밸런서를 생성하기 위해 annotations을 추가했다.

```
[ec2-user@ip-10-0-4-193 kubernetes]$ kubectl apply -f service.yaml
```

Service 배포

![](https://velog.velcdn.com/images/icandooooo/post/4b284aa0-7ebe-47c9-812c-4c63c3962c67/image.png)

```
kubectl get pods -n ns-github-actions-test
kubectl get svc -n ns-github-actions-test
```

위의 명령어를 이용해 제대로 배포되었는지 확인할 수 있다. Pod 상태와 서비스 상태를 확인했다.

![](https://velog.velcdn.com/images/icandooooo/post/5a5a0c5c-7263-4cce-9c45-a1295a996810/image.png)

EXTERNAL-IP를 이용해 외부에서 웹 애플리케이션에 접근할 수 있다.

```
git add .
git status
git commit -m "add Kubernetes Files"
git push origin main
```

### 4) GitHub Actions

![](https://velog.velcdn.com/images/icandooooo/post/eff5058a-efa8-4714-b4ba-0af44f23e47c/image.png)

```
cat ~/.kube/config | base64
```
~/.kube/config 파일을 base64로 인코딩한 후 출력된 값을 GitHub Secrets에 저장했다.

![](https://velog.velcdn.com/images/icandooooo/post/b049c7ae-674f-43e3-b217-d802392fda44/image.png)

AWS ACCESS KEY도 추가했다.

```
[ec2-user@ip-10-0-4-193 github-actions-test]$ mkdir -p .github/workflows/ && cd $_

[ec2-user@ip-10-0-4-193 workflows]$ vi ci-cd.yaml 

name: CI/CD Pipeline
on:
  push:
    branches:
      - main

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    # 1. 코드 체크아웃
    - name: Checkout code
      uses: actions/checkout@v3

    # 2. Docker 로그인
    - name: Log in to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    # 3. Docker 이미지 빌드 및 푸시
    - name: Build and push Docker image
      run: |
        docker build -t ${{ secrets.DOCKER_USERNAME }}/github-action-test:latest .
        docker push ${{ secrets.DOCKER_USERNAME }}/github-action-test:latest

    # 4. AWS EKS 클러스터 설정
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v3
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ap-northeast-2

    # 5. EKS kubeconfig 생성 및 환경 변수 설정
    - name: Set kubeconfig as an environment variable
      run: |
        aws eks update-kubeconfig --region ap-northeast-2 --name hotsun-eks-yiztG3Cs
        export KUBECONFIG=$HOME/.kube/config
        echo "KUBECONFIG=$HOME/.kube/config" >> $GITHUB_ENV

    # 6. kubectl을 사용한 EKS 배포
    - name: Deploy to EKS
      run: |
        kubectl apply -f kubernetes/namespace.yaml
        kubectl apply -f kubernetes/deployment.yaml
        kubectl apply -f kubernetes/service.yaml

```
ci-cd.yaml파일을 작성했다. (.github/workflows 아래에 작성해 주어야 한다.)

#### on 섹션 : 파이프라인 실행 트리거 설정

```
on:
  push:
    branches:
      - main
```

- 파이프라인이 언제 실행될지를 설정
- **push** 이벤트가 발생할 때마다, 즉 main 브랜치에 코드가 push될 때 이 파이프라인이 자동으로 실행됨

#### jobs 섹션 : 실행할 작업들 정의

```
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
```

- jobs 섹션은 여러 작업들을 정의할 수 있는 섹션
- build-and-deploy 이름의 작업이 정의되어 있음
- runs-on: ubuntu-latest는 Ubuntu 최신 버전의 환경에서 실행됨을 의미

#### steps 섹션 : 작업 내 세부 단계들 정의

```
- name: Checkout code
  uses: actions/checkout@v3
```

코드 체크아웃
- actions/checkout@v3 액션 사용하여 GitHub 저장소의 코드 체크아웃
  -> 파이프라인이 실행될 때 해당 리포지토리에서 최신 코드 가져옴
  
```
- name: Log in to Docker Hub
  uses: docker/login-action@v2
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

Docker 로그인
- Docker Hub에 로그인하는 단계
- 환경 변수 DOCKER_USERNAME과 DOCKER_PASSWORD는 GitHub의 Secrets에 저장된 Docker Hub의 사용자 이름과 비밀번호로 설정되어야 함
- 이 정보를 사용해 Docker Hub에 로그인하여 이미지 푸시 권한 얻음

```
- name: Build and push Docker image
  run: |
    docker build -t $DOCKER_USERNAME/github-action-test:latest .
    docker push $DOCKER_USERNAME/github-action-test:latest
```

Docker 이미지 빌드 및 푸시
- Docker 이미지 빌드 및 Docker Hub에 푸시
- Dockerfile을 기반으로 이미지 빌드 후 github-action-test 이름으로 최신 버전 태그
- docker push 명령어를 이용해 빌드한 이미지를 Docker Hub에 푸시하여 저장

```
- name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v3
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ap-northeast-2
```

AWS EKS 클러스터 설정
- AWS 자격 증명 설정 단계
- AWS_ACCESS_KEY_ID와 AWS_SECRET_ACCESS_KEY는 AWS 자격 증명 -> GitHub Secrets에 저장되어야 하며, AWS 리소스에 접근할 수 있는 권한 제공
- aws-region : EKS 클러스터가 위치한 AWS 지역(ap-northeast-2(서울 리전))

```
- name: Set kubeconfig as an environment variable
  run: |
    aws eks update-kubeconfig --region ap-northeast-2 --name hotsun-eks-yiztG3Cs
    export KUBECONFIG=$HOME/.kube/config
    echo "KUBECONFIG=$HOME/.kube/config" >> $GITHUB_ENV
```

EKS kubeconfig 생성 및 환경 변수 설정
- aws eks update-kubeconfig 명령어를 사용하여 EKS 클러스터의 kubeconfig 파일 생성 또는 업데이트
- KUBECONFIG 환경 변수를 설정하여 kubectl이 클러스터에 접근할 수 있도록 함
- echo "KUBECONFIG=$HOME/.kube/config"로 이 환경 변수를 GitHub Actions 환경 변수로 설정

```
- name: Deploy to EKS
  run: |
    kubectl apply -f kubernetes/namespace.yaml
    kubectl apply -f kubernetes/deployment.yaml
    kubectl apply -f kubernetes/service.yaml
```

kubectl을 사용한 EKS 배포
- kubectl apply 명령어를 사용하여 Kubernetes 클러스터에 Namespace, Deployment, Service 리소스 배포
  - kubernetes/namespace.yaml: Kubernetes 네임스페이스 정의
  - kubernetes/deployment.yaml: 애플리케이션 배포 정의
  - kubernetes/service.yaml: 애플리케이션에 서비스 정의

#### 전체 흐름
- 코드 체크아웃
- Docker Hub 로그인
- Docker 이미지 빌드 및 푸시
- AWS EKS 클러스터 설정
- EKS kubeconfig 설정
- kubectl을 통해 EKS 클러스터에 배포

#### main 브랜치에 푸시

```
git add .
git commit -m "add CI/CD pipeline"
git push origin main
```

작성한 GitHub Actions 워크플로우는 main 브랜치에 코드가 푸시될 때 트리거된다.

![](https://velog.velcdn.com/images/icandooooo/post/506a1c92-8ce7-4de6-97bf-e4ab9ed60b66/image.png)

많은 ci-cd.yaml 파일의 수정 끝에 워크플로우가 성공적으로 완료되었다. 초록색 체크 표시는 모든 단계가 정상적으로 실행되어 코드 빌드, 테스트, 배포가 완료되었다는 뜻이다.

---

food.tar 파일의 내용을 조금 바꾸어 정상적으로 작동하는지 눈으로 확인해보겠다.

![](https://velog.velcdn.com/images/icandooooo/post/fde28fd2-8094-4e51-a7bb-8107d9c72de3/image.png)

index.html 파일을 수정해서 push했다.

![](https://velog.velcdn.com/images/icandooooo/post/47017c01-f04e-4ef1-a68e-aa25ed207e19/image.png)

Docker Hub에 이미지가 잘 푸시된다.

![](https://velog.velcdn.com/images/icandooooo/post/8edd4d53-7d38-4a49-a769-f409c8cf168f/image.png)

```
sudo docker pull mjtwinsbbc/github-action-test:latest
sudo docker run -d -p 80:80 mjtwinsbbc/github-action-test:latest
```

Docker Hub에서 이미지를 pull해와서 run하면 EC2의 public ip주소로 접속했을 때 수정한 내용이 잘 적용된다.

## 문제 해결

CI는 정상적으로 작동했지만, CD 과정에서 배포가 제대로 이루어지지 않는 문제가 발생했다.

```
# 7. 배포 후 강제 재시작
    - name: Restart deployment to apply new image
      run: |
        kubectl rollout restart deployment/food-app -n ns-github-actions-test
```
이를 해결하기 위해 CI/CD 파이프라인의 ci-cd.yaml 파일에 위 내용을 추가했다. 쿠버네티스 클러스터에 배포된 Deployment를 강제로 재시작하여 최신 Docker 이미지를 적용하는 코드다.

위 내용을 추가한 후 GitHub에 변경 사항을 Push하면 자동으로 CI/CD 파이프라인이 실행되고, 쿠버네티스 클러스터에 새로운 이미지를 적용한 배포가 성공적으로 이루어졌다.

![](https://velog.velcdn.com/images/icandooooo/post/cbaa1e18-3c38-47d3-8785-9b05821aa641/image.png)

이제 GitHub에 Push할 때마다 자동으로 CI/CD 파이프라인이 실행되고, 쿠버네티스 클러스터에 배포까지 완료하였다.
