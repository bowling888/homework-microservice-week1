# syntax=docker/dockerfile:1.7
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /app
EXPOSE 8080
COPY bin/Release/net8.0/publish/ ./
CMD ["dotnet","csharp_service.dll"]

