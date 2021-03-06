//import { database } from 'faker'
import sql from 'mssql'

const dbsetting = {
    user: "SA",
    password: "BD2_Grupo1",
    server: "db",
    database: "CarDealership_OLTP1",
    options: {
        encrypt: true,
        trustServerCertificate: true,
        cryptoCredentialsDetails: {
            minVersion: 'TLSv1'
        },
    port:1433
    }
};

export async function getConnection(){
    try {
        const pool = await sql.connect(dbsetting);
        //const rest = await pool.request().query('SELECT 1');
        //console.log(rest);
        return pool;
    } catch (error) {
        console.error(error)
    }

}

export {sql};
