#!/bin/bash
## Define token
export onecx_token=eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJFOGU0NjVtNW0wTGFlRTQ3aFNwYjJOZzgtbVdkUVJoN1VWT1RxVUhuTkJzIn0.eyJleHAiOjE3MTc3MDIxNDUsImlhdCI6MTcxNzcwMTg0NSwiYXV0aF90aW1lIjoxNzE3NzAxODQ1LCJqdGkiOiIzNTQ3OGNkOC02MjlkLTRmMmEtYjc3OC0yOTE0MDYxNTk3MDciLCJpc3MiOiJodHRwOi8va2V5Y2xvYWstYXBwL3JlYWxtcy9HaWdhYml0SHViIiwiYXVkIjoib25lY3gtc2hlbGwtdWktY2xpZW50Iiwic3ViIjoiNDliNDBmZTUtOGU5Yy00MDZlLWI5YmQtZmNhMzEzZmRiZTEzIiwidHlwIjoiSUQiLCJhenAiOiJvbmVjeC1zaGVsbC11aS1jbGllbnQiLCJub25jZSI6IjE1MTYxYzZkLWE5MDAtNDVmMi04MWJiLWIwZDAzMTdmNGJmMiIsInNlc3Npb25fc3RhdGUiOiIyODg1ZTk2Ny04MTgxLTRkOWYtYWY0Zi1lNWFmY2Q2YmFhYzAiLCJhdF9oYXNoIjoiM1hkMnp1UmRlY2ZtZ1lYMl93M2w2QSIsImFjciI6IjEiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwicHJlZmVycmVkX3VzZXJuYW1lIjoib25lY3gtZHRhZyIsIm9yZ0lkIjoib25lY3gifQ.g9X8ZZmfsWAraGUkRBr8gRZ67LZNUzKOjGrPNUcx5ESkeyIB0UWRW9LYNxsdFkXagg0wO4RaTE9KcIXoEux81U3OghZTPekCVbAe82LqdfCRIfMBZy-XKL3MZNa9NY-DyZRE4-7wMzMDNXbmLEiOGbS5bdlNpDzfEyZdm449hRZD8FSBoO2zt9YJFuLUVvA4Lpu7kjBursHhH2HNltvt6JEOBpjajnTiSNdqFRNqlNKrdogAW2r3yEvP_gK28BgUr-nggkD35fWRDwj4McdFvR1RNGLIzeYNfLAIIceQeAdEN_LLut023kpuC1SOBkJHTiaBefHbD1NbUyOCQNho0w

cd imports/tenant

echo " "
bash ./import-tenants.sh

cd ../theme

echo " "
bash ./import-themes.sh

cd ../product-store

echo " "
bash ./import-products.sh
echo " "
bash ./import-slots.sh
echo " "
bash ./import-microservices.sh
echo " "
bash ./import-microfrontends.sh

cd ../permissions

echo " "
bash ./import-permissions.sh

cd ../assignments

echo " "
bash ./import-assignments.sh

cd ../workspace

echo " "
bash ./import-workspaces.sh

cd ../..
