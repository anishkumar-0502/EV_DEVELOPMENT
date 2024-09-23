import React, { useState } from 'react';
import EV2 from '../../assets/images/EV_Logo2.png';
import axios from 'axios';

const Sessionlog = () => {
    const [chargerId, setChargerId] = useState('');
    const [responseData, setResponseData] = useState([]);
    const [showTable, setShowTable] = useState(false);
    const [error, setError] = useState('');

    const handleSearch = async () => {
        try {
            if (!chargerId) {
                setError('Charger ID is required.');
                return;
            }

            const response = await axios.get(`/checkChargerID?charger_id=${chargerId}`);

            if (Array.isArray(response.data.value)) {
                setResponseData(response.data.value);
                setShowTable(true);
                setError('');
            } else {
                setResponseData([]);
                setShowTable(false);
                setError('No data found.');
            }
        } catch (error) {
            console.error('Error fetching data:', error);
            if (error.response && error.response.status === 401) {
                setError(error.response.data.message);
            } else {
                setError('Error fetching data. Please try again.');
            }
            setResponseData([]);
            setShowTable(false);
        }
    };

    const formatTimestamp = (timestamp) => {
        const date = new Date(timestamp);
        return date.toLocaleString(); // Adjust the format as needed
    };

    return (
        <div className="container-fluid">
                                <div className="navbar navbar-light bg-none shadow-none p-none fixed-top">
                        <a className="navbar-brand" href="/Home">
                            <img src={EV2} className="ml-2" alt="logo" style={{ width: '150px' }} />
                        </a>
                    </div>
            <div className="row">
                <div className="col-lg-12">
                    <div className="justify-content-center align-items-center" style={{marginBottom: "80px" }}>
                        <div className="mb-4 text-center" style={{marginTop: "100px"}}>
                            <h3 style={{ marginBottom: "30px" }}><b>Session Details</b></h3>
                            <div className="input-group mb-4">
                                <input
                                    type="text"
                                    className="form-control"
                                    placeholder="Enter Charger ID"
                                    value={chargerId}
                                    onChange={(e) => setChargerId(e.target.value)}
                                    required
                                />
                                <div className="input-group-append">
                                    <button className="btn btn-primary" type="button" onClick={handleSearch}>Search</button>
                                </div>
                            </div>
                            {error && <div className="text-danger">{error}</div>}
                        </div>
                    </div>

                    {showTable && responseData.length > 0 && (
                        <div className="table-responsive" style={{maxHeight: '400px'}}>
                            <table className="table table-striped table-bordered table-hover">
                                <thead>
                                    <tr>
                                        <th>Sl. no.</th>
                                        <th>Charger ID</th>
                                        <th>Session ID</th>
                                        <th>Start time</th>
                                        <th>Stop Time</th>
                                        <th>Unit Consumed</th>
                                        <th>Price</th>
                                        <th>User</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {responseData.map((item, index) => (
                                        <tr key={index}>
                                            <td>{index + 1}</td>
                                            <td>{item.ChargerID}</td>
                                            <td>{item.ChargingSessionID}</td>
                                            <td>{formatTimestamp(item.StartTimestamp)}</td>
                                            <td>{formatTimestamp(item.StopTimestamp)}</td>
                                            <td>{item.Unitconsumed}</td>
                                            <td>{item.price}</td>
                                            <td>{item.user}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default Sessionlog;