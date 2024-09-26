import React, {useState, useEffect, useRef, useCallback} from 'react';
import axios from 'axios';
import Header from '../components/Header';
import Sidebar from '../components/Sidebar';
import Footer from '../components/Footer';
import Swal from 'sweetalert2';

const OutputTypeConfig = ({ userInfo, handleLogout }) => {

    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [filteredData] = useState([]);
    const [posts, setPosts] = useState([]);
    const fetchUserRoleCalled = useRef(false);
    const [initialOutputTypeConfig, setInitialOutputTypeConfig] = useState('');

    // Fetch Output Type Config
    const fetchTagID = useCallback(async () => {
        try {
            const res = await axios.post('/superadmin/fetchAllOutputType', {
                association_id: userInfo.data.association_id
            });
    
            if (res.data && res.data.status === 'Success') {
                if (typeof res.data.data === 'string' && res.data.data === 'No Output Type found') {
                    // If the response indicates no tags were found
                    setError(res.data.data);
                    setData([]); // Clear the data since no tags were found
                } else if (Array.isArray(res.data.data)) {
                    setData(res.data.data);
                    setError(null); // Clear any previous errors
                } else {
                    setError('Unexpected response format.');
                }
            } else {
                setError('Error fetching data. Please try again.');
            }
            setLoading(false);
        } catch (err) {
            console.error('Error fetching data:', err);
            setError('Error fetching data. Please try again.');
            setLoading(false);
        }
    }, [userInfo.data.association_id]);

    useEffect(() => {
        if (!fetchUserRoleCalled.current) {
            fetchTagID();
            fetchUserRoleCalled.current = true;
        }
    }, [fetchTagID]);

    // Search data 
    const handleSearchInputChange = (e) => {
        const inputValue = e.target.value.toUpperCase();
        if (Array.isArray(data)) {
            const filteredData = data.filter((item) =>
                item.output_type.toUpperCase().includes(inputValue) ||
                item.output_type_name.toUpperCase().includes(inputValue)
            );
            setPosts(filteredData);
        }
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

    // Add Output Type Config
    const [showAddForm, setShowAddForm] = useState(false);

    const addChargers = () => {
        setShowAddForm(prevState => !prevState); // Toggles the form visibility
    };
    const closeAddModal = () => {
        setOutputTypeConfig(''); 
        setOutputType('');
        setShowAddForm(false); // Close the form
        setTheadsticky('sticky');
        setTheadfixed('fixed');
        setTheadBackgroundColor('white');

    };
    const modalAddStyle = {
        display: showAddForm ? 'block' : 'none',
    }

    // Add Output Type Config
    const [add_OutputType, setOutputType]  = useState('');
    const [add_OutputTypeConfig, setOutputTypeConfig] = useState('');

    const addOutputTypeConfig = async (e) => {
        e.preventDefault();
        try {
            const response = await fetch('/superadmin/createOutputType', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ output_type:add_OutputType, output_type_name:add_OutputTypeConfig, created_by: userInfo.data.email_id }),
            });
            if (response.ok) {
                Swal.fire({
                    title: "Add Output Type Config successfully",
                    icon: "success"
                });
                setOutputTypeConfig(''); 
                setOutputType('');
                setShowAddForm(false);
                closeAddModal();
                fetchTagID();
                setTheadsticky('sticky');
                setTheadfixed('fixed');
                setTheadBackgroundColor('white');
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: responseData.message,
                    icon: "error"
                });
            }
        }catch (error) {
            Swal.fire({
                title: "Error:", error,
                text: "An error occurred while adding Output Type Config",
                icon: "error"
            });
        }
    };

    // Select model 
    const handleModel = (e) => {
        setOutputType(e.target.value);
    };
    // Edit Output Type Config
    const [showEditForm, setShowEditForm] = useState(false);
    const [dataItem, setEditDataItem] = useState(null);

    const handleEditUser = (dataItem) => {
        setEditDataItem(dataItem);
        setEditOutputTypeConfig(dataItem.output_type_name); 
        setInitialOutputTypeConfig(dataItem.output_type_name); 
        setShowEditForm(true); 
    };

    const closeEditModal = () => {
        setShowEditForm(false); // Close the form
        setTheadsticky('sticky');
        setTheadfixed('fixed');
        setTheadBackgroundColor('white');
    };

    const modalEditStyle = {
        display: showEditForm ? 'block' : 'none',
    }
 
    const [theadBackgroundColor, setTheadBackgroundColor] = useState('white');
    const [theadsticky, setTheadsticky] = useState('sticky');
    const [theadfixed, setTheadfixed] = useState('fixed');

    // Edit button thead bgcolor
    const handleEditOutputTypeConfig = (dataItem) => {
        handleEditUser(dataItem);
        setTheadsticky(theadsticky === 'sticky' ? '' : 'sticky');
        setTheadfixed(theadfixed === 'fixed' ? 'transparent' : 'fixed');
        setTheadBackgroundColor(theadBackgroundColor === 'white' ? 'transparent' : 'white');
    };

    // Add button thead bgcolor
    const handleAddAddOutputTypeConfig = () => {
        addChargers();
        setTheadsticky(theadsticky === 'sticky' ? '' : 'sticky');
        setTheadfixed(theadfixed === 'fixed' ? 'transparent' : 'fixed');
        setTheadBackgroundColor(theadBackgroundColor === 'white' ? 'transparent' : 'white');
    }

    // Edit Output Type Config
    const [output_type_name, setEditOutputTypeConfig] = useState('');

    const editOutputTypeConfig = async (e) => {
        e.preventDefault();
        try {
            const response = await fetch('/superadmin/updateOutputType', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ id:dataItem.id, output_type_name, modified_by: userInfo.data.email_id}),
            });
            if (response.ok) {
                Swal.fire({
                    title: "Update Output Type Config successfully",
                    icon: "success"
                });
                setEditOutputTypeConfig(''); 
                setShowEditForm(false);
                closeEditModal();
                fetchTagID();
                setTheadsticky('sticky');
                setTheadfixed('fixed');
                setTheadBackgroundColor('white');
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: responseData.message,
                    icon: "error"
                });
            }
        }catch (error) {
            Swal.fire({
                title: "Error:", error,
                text: "An error occurred while update Output Type Config",
                icon: "error"
            });
        }
    };

    // DeActive
    const changeDeActivate = async (e, id) => {
        e.preventDefault();
        try {
            const response = await fetch('/superadmin/DeActivateOutputType', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ id, status:false, modified_by: userInfo.data.email_id }),
            });
            if (response.ok) {
                Swal.fire({
                    title: "DeActivate successfully",
                    icon: "success"
                });
                fetchTagID();
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to DeActivate, " + responseData.message,
                    icon: "error"
                });
            }
        }catch (error) {
            Swal.fire({
                title: "Error:", error,
                text: "An error occurred while adding DeActivate",
                icon: "error"
            });
        }
    };

    // Active
    const changeActivate = async (e, id) => {
        e.preventDefault();
        try {
            const response = await fetch('/superadmin/DeActivateOutputType', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ id, status:true, modified_by: userInfo.data.email_id }),
            });
            if (response.ok) {
                Swal.fire({
                    title: "Activate successfully",
                    icon: "success"
                });
                fetchTagID();
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to Activate, " + responseData.message,
                    icon: "error"
                });
            }
        }catch (error) {
            Swal.fire({
                title: "Error:", error,
                text: "An error occurred while adding Activate",
                icon: "error"
            });
        }
    };

    // Timestamp data 
    function formatTimestamp(originalTimestamp) {
        const date = new Date(originalTimestamp);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        
        let hours = date.getHours();
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const seconds = String(date.getSeconds()).padStart(2, '0');
        const ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        hours = String(hours).padStart(2, '0');
    
        const formattedDate = `${day}/${month}/${year} ${hours}:${minutes}:${seconds} ${ampm}`;
        return formattedDate;
    }
    
    return (
        <div className='container-scroller'>
            {/* Header */}
            <Header userInfo={userInfo} handleLogout={handleLogout} />
            <div className="container-fluid page-body-wrapper">
                {/* Sidebar */}
                <Sidebar/>
                <div className="main-panel">
                    <div className="content-wrapper">
                        <div className="row">
                            <div className="col-md-12 grid-margin">
                                <div className="row">
                                    <div className="col-12 col-xl-8 mb-4 mb-xl-0">
                                        <h3 className="font-weight-bold">Output Type Config</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            <button type="button" className="btn btn-success" onClick={handleAddAddOutputTypeConfig}>Add Output Type Config</button>
                                            {/* Add Output Type Config start */}
                                            <div className="modalStyle" style={modalAddStyle}>
                                                <div className="modalContentStyle" style={{ maxHeight: '680px', overflowY: 'auto' }}>
                                                    <span onClick={closeAddModal} style={{ float: 'right', cursor: 'pointer', fontSize:'30px' }}>&times;</span>
                                                    <form className="pt-3" onSubmit={addOutputTypeConfig}>
                                                        <div className="card-body">
                                                            <div style={{textAlign:'center'}}>
                                                                <h4 className="card-title">Add Output Type Config</h4>
                                                            </div>
                                                            <div className="table-responsive pt-3">
                                                                <div className="input-group" style={{paddingRight:'1px'}}>
                                                                    <div className="input-group-prepend">
                                                                        <span className="input-group-text" style={{color:'black', width:'150px'}}>Type</span>
                                                                    </div>
                                                                    <select className="form-control"  style={{paddingRight:'10px'}} value={add_OutputType} onChange={handleModel} required>
                                                                        <option value="">Select Type</option>
                                                                        <option value="Gun">Gun</option>
                                                                        <option value="Socket">Socket</option>
                                                                    </select>
                                                                </div>
                                                                <div className="input-group">
                                                                    <div className="input-group-prepend">
                                                                        <span className="input-group-text" style={{color:'black', width:'150px'}}>Type Name</span>
                                                                    </div>
                                                                    <input type="text" className="form-control" placeholder="Output Type Name" value={add_OutputTypeConfig} onChange={(e) => {const value = e.target.value; const sanitizedValue = value; setOutputTypeConfig(sanitizedValue);}} required/>
                                                                </div>
                                                            </div>
                                                            <div style={{textAlign:'center'}}>
                                                                <button type="submit" className="btn btn-primary mr-2" style={{marginTop:'10px'}}>Add</button>
                                                            </div>
                                                        </div>
                                                    </form>
                                                </div>
                                            </div>
                                            {/* Add Output Type Config end */}
                                            {/* Edit Output Type Config start */}
                                            <div className="modalStyle" style={modalEditStyle}>
                                                <div className="modalContentStyle" style={{ maxHeight: '680px', overflowY: 'auto' }}>
                                                    <span onClick={closeEditModal} style={{ float: 'right', cursor: 'pointer', fontSize:'30px' }}>&times;</span>
                                                    <form className="pt-3" onSubmit={editOutputTypeConfig}>
                                                        <div className="card-body">
                                                            <div style={{textAlign:'center'}}>
                                                                <h4 className="card-title">Edit Output Type Config</h4>
                                                            </div>
                                                            <div className="table-responsive pt-3">
                                                                <div className="input-group">
                                                                    <div className="input-group-prepend">
                                                                        <span className="input-group-text" style={{ color: 'black', width: '180px' }}>Type</span>
                                                                    </div>
                                                                    <input type="text" className="form-control" placeholder="Output Type" style={{ width:'200px'}}   value={dataItem?.output_type || ''}readOnly/>
                                                                </div>
                                                                <div className="input-group">
                                                                    <div className="input-group-prepend">
                                                                        <span className="input-group-text" style={{ color: 'black', width: '180px' }}>Type Name</span>
                                                                    </div>
                                                                    <input type="text" className="form-control" placeholder="Output Type Name" style={{ width:'200px'}} 
                                                                        value={output_type_name} onChange={(e) => setEditOutputTypeConfig(e.target.value)}required/>
                                                                </div>
                                                            </div>
                                                            <div style={{textAlign:'center'}}>
                                                                <button type="submit" className="btn btn-primary mr-2" style={{marginTop:'10px'}} disabled={output_type_name === initialOutputTypeConfig}>Update</button>
                                                            </div>
                                                        </div>
                                                    </form>
                                                </div>
                                            </div>
                                            {/* Edit Output Type Config end */}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="row">
                            <div className="col-lg-12 grid-margin stretch-card">
                                <div className="card">
                                    <div className="card-body">
                                        <div className="row">
                                            <div className="col-md-12 grid-margin">
                                                <div className="row">
                                                    <div className="col-4 col-xl-8">
                                                        <h4 className="card-title" style={{paddingTop:'10px'}}>List Of Output Type Config</h4>  
                                                    </div>
                                                    <div className="col-8 col-xl-4">
                                                        <div className="input-group">
                                                            <div className="input-group-prepend hover-cursor" id="navbar-search-icon">
                                                                <span className="input-group-text" id="search">
                                                                <i className="icon-search"></i>
                                                                </span>
                                                            </div>
                                                            <input type="text" className="form-control" placeholder="Search by Output Type/Name" aria-label="search" aria-describedby="search" autoComplete="off" onChange={handleSearchInputChange}/>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div className="table-responsive" style={{ maxHeight: '500px', overflowY: 'auto' }}>
                                            <table className="table table-striped">
                                                <thead style={{ textAlign: 'center', position: theadsticky, tableLayout: theadfixed, top: 0, backgroundColor: theadBackgroundColor, zIndex: 1 }}>
                                                    <tr> 
                                                        <th>Sl.No</th>
                                                        <th>Output Type</th>
                                                        <th>Output Type Name</th>
                                                        <th>Created By</th>
                                                        <th>Created Date</th>
                                                        <th>Modified By</th>
                                                        <th>Modified Date</th>
                                                        <th>Status</th>
                                                        <th>Active/DeActive</th>
                                                        <th>Option</th>
                                                    </tr>
                                                </thead>
                                                <tbody style={{textAlign:'center'}}>
                                                    {loading ? (
                                                        <tr>
                                                            <td colSpan="10" style={{ marginTop: '50px', textAlign: 'center' }}>Loading...</td>
                                                        </tr>
                                                    ) : error ? (
                                                        <tr>
                                                            <td colSpan="10" style={{ marginTop: '50px', textAlign: 'center' }}>Error: {error}</td>
                                                        </tr>
                                                    ) : (
                                                        Array.isArray(posts) && posts.length > 0 ? (
                                                            posts.map((dataItem, index) => (
                                                            <tr key={index}>
                                                                <td>{index + 1}</td>
                                                                <td>{dataItem.output_type ||'-'}</td>
                                                                <td>{dataItem.output_type_name ||'-'}</td>
                                                                <td>{dataItem.created_by ? dataItem.created_by : '-'}</td>
                                                                <td>{dataItem.created_date ? formatTimestamp(dataItem.created_date) : '-'}</td>
                                                                <td>{dataItem.modified_by ? dataItem.modified_by : '-'}</td>
                                                                <td>{dataItem.modified_date ?  formatTimestamp(dataItem.modified_date) : '-'}</td>
                                                                <td>{dataItem.status===true ? <span className="text-success">Active</span> : <span className="text-danger">DeActive</span>}</td>
                                                                <td>
                                                                    <div className='form-group' style={{paddingTop:'13px'}}> 
                                                                        {dataItem.status===true ?
                                                                            <div className="form-check form-check-danger">
                                                                                <label className="form-check-label"><input type="radio" className="form-check-input" name="optionsRadios1" id="optionsRadios2" value={false} onClick={(e) => changeDeActivate(e, dataItem.id)}/>DeActive<i className="input-helper"></i></label>
                                                                            </div>
                                                                        :
                                                                            <div className="form-check form-check-success">
                                                                                <label className="form-check-label"><input type="radio" className="form-check-input" name="optionsRadios1" id="optionsRadios1" value={true} onClick={(e) => changeActivate(e, dataItem.id)}/>Active<i className="input-helper"></i></label>
                                                                            </div>
                                                                        }
                                                                    </div>
                                                                </td>
                                                                <td>
                                                                    <button type="button" className="btn btn-outline-primary btn-icon-text"  onClick={() => handleEditOutputTypeConfig(dataItem)} style={{marginBottom:'10px'}}><i className="mdi mdi-pencil btn-icon-prepend"></i>Edit</button><br/>
                                                                </td>                                                    
                                                            </tr>
                                                        ))
                                                        ) : (
                                                        <tr>
                                                            <td colSpan="10" style={{ marginTop: '50px', textAlign: 'center' }}>No Output Type Config found</td>
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
                 
export default OutputTypeConfig