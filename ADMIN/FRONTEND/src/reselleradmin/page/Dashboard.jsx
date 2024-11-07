import React, { useState, useEffect, useCallback, useRef } from 'react';
import Header from '../components/Header';
import Sidebar from '../components/Sidebar';
import Footer from '../components/Footer';
import axios from 'axios';
import Chart from 'chart.js/auto';

const Dashboard = ({ userInfo, handleLogout }) => {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [filteredData] = useState([]);
    const [posts, setPosts] = useState([]); 
    const chartRef = useRef(null);
    const fetchAllocatedChargerDetailsCalled = useRef(false); 

    // Fetch allocated charger details
    const fetchAllocatedChargerDetails = useCallback(async () => {
        try {
            const response = await axios.post('/reselleradmin/FetchAllocatedCharger', {
                reseller_id: userInfo.data.reseller_id,
            });
            console.log(response);

            setData(response.data.data || []);
            setLoading(false);
        } catch (error) {
            setError('Error fetching data. Please try again.');
            setLoading(false);
            console.error('Error fetching allocated charger details:', error);
            // Handle error appropriately, such as showing an error message to the user
        }
    }, [userInfo.data.reseller_id]);

    useEffect(() => {
        if (!fetchAllocatedChargerDetailsCalled.current) {
            const fetchAllocatedChargers = async () => {
                await fetchAllocatedChargerDetails();
            };

            fetchAllocatedChargers();
            fetchAllocatedChargerDetailsCalled.current = true; // Mark fetchAllocatedChargerDetails as called
        }
    }, [fetchAllocatedChargerDetails]); // Include fetchAllocatedChargerDetails in the dependency array



    // Faulty data onclick show box data
    // const [isBoxVisible, setIsBoxVisible] = useState(false);
    // const toggleBoxVisibility = () => {
    //   setIsBoxVisible(!isBoxVisible);
    // };
    
    // Search data 
    const handleSearchInputChange = (e) => {
        const inputValue = e.target.value.toUpperCase();
        // Filter the data array based on the input value (converted to uppercase)
        const filteredData = data.filter((item) =>
          item.charger_id.toString().toUpperCase().includes(inputValue)
        );
        // Update the search state with the filtered results
        setPosts(filteredData); // Set posts to the filteredData
    };

    // Update table data 'data', and 'filteredData' 
    useEffect(() => {
        switch (data) {
            case 'filteredData':
                setPosts(filteredData);
                break;
            default:
                setPosts(data);
                break;
        }
    }, [data, filteredData]);
    
    // Online, Offline and Faulty charger lengths 
    const onlineChargers = data.filter((post) => post.status === true || post.status === 'true');
    const offlineChargers = data.filter((post) => post.status === false || post.status === 'false');
    // const faultyChargers = data.filter((post) => post.status === 'Faulted');

    // Total chargers count
    const totalChargers = data.length;

    const totalPercentage = (data.length / totalChargers) * 10;
    const onlinePercentage = (onlineChargers.length / totalChargers) * 10;
    const offlinePercentage = (offlineChargers.length / totalChargers) * 10;
    // const faultyPercentage = (faultyChargers.length / totalChargers) * 10;
    
    // Chart data 
    useEffect(() => {
        const xValues = ['Total', 'Online', 'Offline'];
        const yValues = [
            data.length,
            onlineChargers.length,
            offlineChargers.length
        ];
        const barColors = ["#4B46AC", "#57B657", "#FF4747"];

        if (chartRef.current) {
            chartRef.current.destroy();
        }

        const ctx = document.getElementById('myChart').getContext('2d');
        chartRef.current = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: xValues,
                datasets: [{
                    backgroundColor: barColors,
                    data: yValues
                }]
            },
            options: {
                responsive: true, // Ensure the chart is responsive
                maintainAspectRatio: false, // Allow the chart to resize while maintaining aspect ratio
                plugins: {
                    title: {
                        display: true,
                        text: 'Chart Title'
                    }
                }
            }
        });

        return () => {
            if (chartRef.current) {
                chartRef.current.destroy();
            }
        };
    }, [data, onlineChargers.length, offlineChargers.length]);
    
    const fetchDataAndUpdateChart = () => {
        setData([...Array(0)]);
    };
    
    useEffect(() => {
        fetchDataAndUpdateChart();
    }, []);

    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header userInfo={userInfo} handleLogout={handleLogout}/>
            <div className="container-fluid page-body-wrapper" style={{paddingTop:'40px'}}>
                {/* Sidebar */}
                <Sidebar/>
                <div className="main-panel">
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">Welcome to <span style={{color:'#4B49AC'}}>{userInfo.data.email_id}</span>,</h3>
                                        <h4 className="font-weight-bold">Reseller Admin Dashboard</h4>
                                    </div>
                                </div>
                            </div>
                        </div>
                        {/* <div className="row">
                            <div className="col-md-6 grid-margin stretch-card">
                                <div className="card tale-bg">
                                    <div className="card-people mt-auto">
                                        <img src="../../images/dashboard/ev_bg_image-2.png" alt="people" />
                                    </div>
                                </div>
                            </div>
                            <div className="col-md-6 grid-margin transparent">
                                <div className="row">
                                    <div className="col-md-6 mb-4 stretch-card transparent">
                                        <div className="card card-tale">
                                            <div className="card-body">
                                                <h4 className="mb-4">Todays Chargers</h4>
                                                <h3 className="fs-30 mb-2">{data.length} Charger's</h3>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="col-md-6 mb-4 stretch-card transparent">
                                        <div className="card card-dark-blue">
                                            <div className="card-body">
                                                <p className="mb-4">Total Bookings</p>
                                                <p className="fs-30 mb-2">61344</p>
                                                <p>22.00% (30 days)</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div className="row">
                                    <div className="col-md-6 mb-4 mb-lg-0 stretch-card transparent">
                                        <div className="card card-light-blue">
                                            <div className="card-body">
                                                <p className="mb-4">Number of Meetings</p>
                                                <p className="fs-30 mb-2">34040</p>
                                                <p>2.00% (30 days)</p>
                                            </div>
                                        </div>
                                    </div>
                                    <div className="col-md-6 stretch-card transparent">
                                        <div className="card card-light-danger">
                                            <div className="card-body">
                                                <p className="mb-4">Number of Clients</p>
                                                <p className="fs-30 mb-2">47033</p>
                                                <p>0.22% (30 days)</p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div> */}
                        <div className="row">
                            <div className="col-md-12 grid-margin stretch-card">
                                <div className="card position-relative">
                                    <div className="card-body">
                                        <div id="detailedReports" className="carousel slide detailed-report-carousel position-static pt-2" data-ride="carousel">
                                            <div className="carousel-inner">
                                                <div className="carousel-item active">
                                                    <div className="row">
                                                        <div className="col-md-12 col-xl-3 d-flex flex-column justify-content-start">
                                                            <div className="ml-xl-4 mt-3">
                                                                <p className="card-title">Reports</p>
                                                                <h1 className="text-primary">1000</h1>
                                                                <h3 className="font-weight-500 mb-xl-4 text-primary">Charged cycles</h3>
                                                                <p className="mb-2 mb-xl-0">This achievement underscores the durability of our chargers, ensuring sustained functionality. It also reflects our commitment to providing a reliable and long-lasting charging infrastructure for electric vehicles.</p>
                                                            </div>  
                                                        </div>
                                                        <div className="col-md-12 col-xl-9">
                                                            <div className="row">
                                                                <div className="col-md-6 border-right">
                                                                    <div className="table-responsive mb-3 mb-md-0 mt-3">
                                                                        <table className="table table-borderless report-table">
                                                                            <tbody>
                                                                                <tr>
                                                                                    <td className="text-muted"><h5>Total</h5>Chargers installed</td>
                                                                                    <td className="w-100 px-0">
                                                                                        <div className="progress progress-md mx-4">
                                                                                            <div className="progress-bar bg-primary" role="progressbar" style={{width:`${totalPercentage}%`}}></div>
                                                                                        </div>
                                                                                    </td>
                                                                                    <td><h5 className="font-weight-bold mb-0">{data.length}</h5></td>
                                                                                </tr>
                                                                                <tr>
                                                                                    <td className="text-muted"><h5>Online</h5>Currently Charging</td>
                                                                                    <td className="w-100 px-0">
                                                                                        <div className="progress progress-md mx-4">
                                                                                            <div className="progress-bar bg-success" role="progressbar"  style={{width:`${onlinePercentage}%`}}></div>
                                                                                        </div>
                                                                                    </td>
                                                                                    <td><h5 className="font-weight-bold mb-0">{onlineChargers.length}</h5></td>
                                                                                </tr>
                                                                                <tr>
                                                                                    <td className="text-muted"><h5>Offline</h5>Not live</td>
                                                                                    <td className="w-100 px-0">
                                                                                        <div className="progress progress-md mx-4">
                                                                                            <div className="progress-bar bg-danger" role="progressbar"  style={{width:`${offlinePercentage}%`}}></div>
                                                                                        </div>
                                                                                    </td>
                                                                                    <td><h5 className="font-weight-bold mb-0">{offlineChargers.length}</h5></td>
                                                                                </tr>
                                                                                {/* <tr onClick={toggleBoxVisibility} className="custom-hover">
                                                                                    <td className="text-muted"><h5>Faulty</h5>Not live</td>
                                                                                    <td className="w-100 px-0">
                                                                                        <div className="progress progress-md mx-4">
                                                                                            <div className="progress-bar bg-warning" role="progressbar"  style={{width:`${faultyPercentage}%`}}></div>
                                                                                        </div>
                                                                                    </td>
                                                                                    <td><h5 className="font-weight-bold mb-0">{faultyChargers.length}</h5></td>
                                                                                </tr> */}
                                                                            </tbody>
                                                                        </table>
                                                                    </div>
                                                                </div>
                                                                <div className="col-md-6 mt-3">
                                                                    <div className="report-chart">
                                                                        <div style={{ width: '70%', height: '70%', margin: 'auto', textAlign: 'center', display: 'flex', justifyContent: 'center', alignItems: 'center'  }}>
                                                                            <canvas id="myChart" style={{ width: '100% !important', height: 'auto !important'}}/>
                                                                        </div>
                                                                    </div>
                                                                    <div>
                                                                        <div className="report-chart">
                                                                            <div className="d-flex justify-content-between mx-4 mx-xl-5 mt-3">
                                                                                <div className="d-flex align-items-center">
                                                                                    <div className="mr-3" style={{width:'20px', height:'20px', borderRadius:'50%', backgroundColor:' #4B49AC'}}></div>
                                                                                        <p className="mb-0">Total</p>
                                                                                </div>
                                                                                        <p className="mb-0">{data.length}</p>
                                                                                </div>
                                                                            <div className="d-flex justify-content-between mx-4 mx-xl-5 mt-3">
                                                                                <div className="d-flex align-items-center">
                                                                                    <div className="mr-3" style={{width:'20px', height:'20px', borderRadius:'50%', backgroundColor:' #57B657'}}></div>
                                                                                    <p className="mb-0">Online </p>
                                                                                </div>
                                                                                        <p className="mb-0">{onlineChargers.length}</p>
                                                                            </div>
                                                                            <div className="d-flex justify-content-between mx-4 mx-xl-5 mt-3">
                                                                                <div className="d-flex align-items-center">
                                                                                    <div className="mr-3" style={{width:'20px', height:'20px', borderRadius:'50%', backgroundColor:' #FF4747'}}></div>
                                                                                    <p className="mb-0">Offline</p>
                                                                                </div>
                                                                                <p className="mb-0">{offlineChargers.length}</p>
                                                                            </div>
                                                                        </div>
                                                                    </div> 
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        {/* {isBoxVisible && (
                            <div className="row">
                                {faultyChargers.map((charger, index) => (
                                    <div key={index} className="col-md-3 mb-4 stretch-card transparent">
                                        <div className="card card-tale">
                                            <div className="card-body" style={{backgroundImage:'url("images/dashboard/hand-holding-ev.png")', backgroundSize: "cover", backgroundRepeat: "no-repeat"}}>
                                                <div style={{padding:'10px',borderRadius:'10px' ,color:'black'}}>
                                                    <h4>CHARGER :  {charger.ChargerID}</h4>
                                                    <h5>{formatTimestamp(charger.timestamp)}</h5>
                                                </div>
                                                    <hr></hr>
                                                <div style={{padding:'10px',borderRadius:'10px' ,background:'#000000ab'}}>
                                                    <h5>Connector : <span>{charger.connector}</span></h5>
                                                    <h5>Error : <span style={{color:'red'}}>{charger.errorCode}</span></h5>
                                                    <h5>Status: <span style={{color:'yellow'}}>{charger.status}</span></h5>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>  
                        )} */}
                        <div className="row">
                            <div className="col-lg-12 grid-margin stretch-card">
                                <div className="card">
                                    <div className="card-body">
                                        <div className="row">
                                            <div className="col-md-12 grid-margin">
                                                <div className="row">
                                                    <div className="col-4 col-xl-8">
                                                        <h4 className="card-title" style={{paddingTop:'10px'}}>List Of Chargers</h4>  
                                                    </div>
                                                    <div className="col-8 col-xl-4">
                                                        <div className="input-group">
                                                            <div className="input-group-prepend hover-cursor" id="navbar-search-icon">
                                                                <span className="input-group-text" id="search">
                                                                <i className="icon-search"></i>
                                                                </span>
                                                            </div>
                                                            <input type="text" className="form-control" placeholder="Search now" aria-label="search" aria-describedby="search" autoComplete="off" onChange={handleSearchInputChange}/>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div className="table-responsive" style={{ maxHeight: '300px', overflowY: 'auto' }}>
                                            <table className="table table-striped">
                                                <thead style={{ textAlign: 'center', tableLayout: 'fixed', position: 'sticky', top: 0, backgroundColor: 'white', zIndex: 1 }}>
                                                    <tr> 
                                                        <th>Sl.No</th>
                                                        <th>Charger ID</th>
                                                        <th>Charger Model</th>
                                                        <th>Charger Type</th>
                                                        <th>Max Current</th>
                                                        <th>Status</th>
                                                    </tr>
                                                </thead>
                                                <tbody style={{textAlign:'center'}}>
                                                    {loading ? (
                                                        <tr>
                                                            <td colSpan="9" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                        </tr>
                                                    ) : error ? (
                                                        <tr>
                                                        <td colSpan="9" style={{ marginTop: '50px', textAlign: 'center' }}>Error: {error}</td>
                                                        </tr>
                                                    ) : (
                                                        Array.isArray(posts) && posts.length > 0 ? (
                                                            posts.map((dataItem, index) => (
                                                            <tr key={index}>
                                                                <td>{index + 1}</td>
                                                                <td>{dataItem.charger_id ? (
                                                                    <span>{dataItem.charger_id}</span>
                                                                    ): (
                                                                        <span>-</span> 
                                                                    )}
                                                                </td>
                                                                <td className="py-1">
                                                                    <img src={`../../images/dashboard/${dataItem.charger_model ? dataItem.charger_model : '-'}kw.png`} alt="img" />
                                                                </td>
                                                                <td>{dataItem.charger_type ? (
                                                                    <span>{dataItem.charger_type}</span>
                                                                    ): (
                                                                        <span>-</span> 
                                                                    )}
                                                                </td>
                                                                <td>{dataItem.max_current ? (
                                                                    <span>{dataItem.max_current}</span>
                                                                    ) : (
                                                                    <span>-</span>
                                                                    )}
                                                                </td>
                                                                <td>{dataItem.status === true ? (
                                                                        <span className="text-success">Active</span>
                                                                    ) : dataItem.status === false ? (
                                                                        <span className="text-danger">DeActive</span>
                                                                    ) : (
                                                                        <span>-</span>
                                                                    )}
                                                                </td>
                                                            </tr>
                                                        ))
                                                        ) : (
                                                        <tr>
                                                            <td colSpan="6" style={{ marginTop: '50px', textAlign: 'center' }}>No devices found.</td>
                                                        </tr>
                                                        )
                                                    )}
                                                </tbody> 
                                            </table>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    {/* Footer */}
                    <Footer />
                </div>         
            </div>    
        </div>
    );
};  

export default Dashboard