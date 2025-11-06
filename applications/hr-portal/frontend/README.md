# HR Portal Frontend (React)

This is a template/starter for the HR Portal frontend application.

## Features (To Implement)

- Employee management dashboard
- Employee CRUD operations
- Workspace status monitoring
- User authentication
- Role-based UI elements

## Structure

```
src/
├── components/
│   ├── EmployeeList.jsx
│   ├── EmployeeForm.jsx
│   ├── WorkspaceStatus.jsx
│   └── Navigation.jsx
├── pages/
│   ├── Dashboard.jsx
│   ├── Employees.jsx
│   └── Login.jsx
├── services/
│   └── api.js
├── App.jsx
└── index.js
```

## Getting Started

```bash
npm install
npm start
```

## API Integration

Configure API endpoint in `.env`:
```
REACT_APP_API_URL=http://hr-portal-backend.hr-portal
```

## Build for Production

```bash
npm run build
```

Then create Dockerfile:
```dockerfile
FROM nginx:alpine
COPY build/ /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## Next Steps

1. Implement authentication flow
2. Create employee management components
3. Add workspace monitoring dashboard
4. Build Dockerfile and push to ECR
5. Update kubernetes/hr-portal.yaml with frontend image
