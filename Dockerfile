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

