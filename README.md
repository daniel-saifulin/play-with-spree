# Development setup

1. Build: `docker-compose build`
1. Run docker images: `docker-compose up`
2. Create DBs: `docker-compose exec web rake db:create`
3. Run migrations: `docker-compose exec web rake db:migrate`
3. Run seeds: `docker-compose exec web rake db:seed`

App will be available under `http://localhost:3000`
Admin can import products under `http://localhost:3000/admin/products`
Login: `spree@example.com`
Password: `spree123`
Please use semicolon(`;`) for column separator