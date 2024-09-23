import React, {useState, useEffect, useRef} from 'react';
import axios from 'axios';
import Header from '../components/Header';
import Sidebar from '../components/Sidebar';
import Footer from '../components/Footer';
import Swal from 'sweetalert2';

const ManageUserRole = ({ userInfo, handleLogout }) => {

    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [filteredData] = useState([]);
    const [posts, setPosts] = useState([]);
    const fetchUserRoleCalled = useRef(false); // Ref to track if fetchProfile has been called
    const [initialRoleEditname, setInitialRoleEditname] = useState('');

    // Fetch user roles
    const fetchUserRoles = async () => {
        try {
            const res = await axios.get('/superadmin/FetchUserRoles');
            setData(res.data.data);
            setLoading(false);
        } catch (err) {
            console.error('Error fetching data:', err);
            setError('Error fetching data. Please try again.');
            setLoading(false);
        }
    };

    useEffect(() => {
        if (!fetchUserRoleCalled.current) {
            fetchUserRoles();
            fetchUserRoleCalled.current = true;
        }
    }, []);


    // Search data 
    const handleSearchInputChange = (e) => {
        const inputValue = e.target.value.toUpperCase();
        if (Array.isArray(data)) {
            const filteredData = data.filter((item) =>
                item.role_name.toUpperCase().includes(inputValue)
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

    // Add user role start 
    // const [showAddForm, setShowAddForm] = useState(false);

    // const addChargers = () => {
    //     setShowAddForm(prevState => !prevState); // Toggles the form visibility
    // };
    // const closeAddModal = () => {
    //     setuserRole(''); 
    //     setShowAddForm(false); // Close the form
    //     setTheadsticky('sticky');
    //     setTheadfixed('fixed');
    //     setTheadBackgroundColor('white');

    // };
    // const modalAddStyle = {
    //     display: showAddForm ? 'block' : 'none',
    // }

    // Add user role
    // const [rolename, setuserRole] = useState('');

    // const addUserRole = async (e) => {
    //     e.preventDefault();
    //     try {
    //         const response = await fetch('/superadmin/CreateUserRole', {
    //             method: 'POST',
    //             headers: {
    //                 'Content-Type': 'application/json',
    //             },
    //             body: JSON.stringify({ rolename, created_by: userInfo.data.email_id }),
    //         });
    //         if (response.ok) {
    //             Swal.fire({
    //                 title: "Add user role successfully",
    //                 icon: "success"
    //             });
    //             setuserRole(''); 
    //             setShowAddForm(false);
    //             closeAddModal();
    //             fetchUserRoles();
    //             setTheadsticky('sticky');
    //             setTheadfixed('fixed');
    //             setTheadBackgroundColor('white');
    //         } else {
    //             const responseData = await response.json();
    //             Swal.fire({
    //                 title: "Error",
    //                 text: "Failed to user role, " + responseData.message,
    //                 icon: "error"
    //             });
    //         }
    //     }catch (error) {
    //         Swal.fire({
    //             title: "Error:", error,
    //             text: "An error occurred while adding user role",
    //             icon: "error"
    //         });
    //     }
    // };

    // Edit user role start 
    const [showEditForm, setShowEditForm] = useState(false);
    const [dataItem, setEditDataItem] = useState(null);
 
    const handleEditUser = (dataItem) => {
        setEditDataItem(dataItem);
        setEdituserRole(dataItem.role_name); // Set role name for editing
        setInitialRoleEditname(dataItem.role_name); // Set initial value for comparison
        setShowEditForm(true); // Open the form
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
    const handleEditUserAndToggleBackground = (dataItem) => {
        handleEditUser(dataItem);
        setTheadsticky(theadsticky === 'sticky' ? '' : 'sticky');
        setTheadfixed(theadfixed === 'fixed' ? 'transparent' : 'fixed');
        setTheadBackgroundColor(theadBackgroundColor === 'white' ? 'transparent' : 'white');
    };

    // Add button thead bgcolor
    // const handleAddUserAndToggleBackground = () => {
    //     addChargers();
    //     setTheadsticky(theadsticky === 'sticky' ? '' : 'sticky');
    //     setTheadfixed(theadfixed === 'fixed' ? 'transparent' : 'fixed');
    //     setTheadBackgroundColor(theadBackgroundColor === 'white' ? 'transparent' : 'white');
    // }

    // Edit user role
    const [roleEditname, setEdituserRole] = useState('');
    
    const editUserRole = async (e) => {
        e.preventDefault();
        try {
            const response = await fetch('/superadmin/UpdateUserRole', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ role_id: dataItem.role_id, role_name: roleEditname, modified_by: userInfo.data.email_id }),
            });
            if (response.ok) {
                Swal.fire({
                    title: "Update user role successfully",
                    icon: "success"
                });
                setEdituserRole(''); 
                setShowEditForm(false);
                closeEditModal();
                fetchUserRoles();
                setTheadsticky('sticky');
                setTheadfixed('fixed');
                setTheadBackgroundColor('white');
            } else {
                const responseData = await response.json();
                Swal.fire({
                    title: "Error",
                    text: "Failed to update user role, " + responseData.message,
                    icon: "error"
                });
            }
        }catch (error) {
            Swal.fire({
                title: "Error:", error,
                text: "An error occurred while update user role",
                icon: "error"
            });
        }
    };

    // DeActive
    const changeDeActivate = async (e, role_id) => {
        e.preventDefault();
        try {
            const response = await fetch('/superadmin/DeActivateOrActivateUserRole', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ role_id, status:false, modified_by: userInfo.data.email_id }),
            });
            if (response.ok) {
                Swal.fire({
                    title: "DeActivate successfully",
                    icon: "success"
                });
                fetchUserRoles();
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
    const changeActivate = async (e, role_id) => {
        e.preventDefault();
        try {
            const response = await fetch('/superadmin/DeActivateOrActivateUserRole', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ role_id, status:true, modified_by: userInfo.data.email_id }),
            });
            if (response.ok) {
                Swal.fire({
                    title: "Activate successfully",
                    icon: "success"
                });
                fetchUserRoles();
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
                                        <h3 className="font-weight-bold">Manage User Role's</h3>
                                    </div>
                                    <div className="col-12 col-xl-4">
                                        <div className="justify-content-end d-flex">
                                            {/* <button type="button" className="btn btn-success" onClick={handleAddUserAndToggleBackground}>Add Role's</button> */}
                                            {/* Add role start */}
                                            {/* <div className="modalStyle" style={modalAddStyle}>
                                                <div className="modalContentStyle" style={{ maxHeight: '680px', overflowY: 'auto' }}>
                                                    <span onClick={closeAddModal} style={{ float: 'right', cursor: 'pointer', fontSize:'30px' }}>&times;</span>
                                                    <form className="pt-3" onSubmit={addUserRole}>
                                                        <div className="card-body">
                                                            <div style={{textAlign:'center'}}>
                                                                <h4 className="card-title">Add Role's</h4>
                                                            </div>
                                                            <div className="table-responsive pt-3">
                                                                <div className="input-group">
                                                                    <div className="input-group-prepend">
                                                                        <span className="input-group-text" style={{color:'black', width:'125px'}}>Role Name</span>
                                                                    </div>
                                                                    <input type="text" className="form-control" placeholder="Role Name" value={rolename} maxLength={25} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/[^a-zA-Z0-9 ]/g, ''); setuserRole(sanitizedValue);}} required/>
                                                                </div>
                                                            </div>
                                                            <div style={{textAlign:'center'}}>
                                                                <button type="submit" className="btn btn-primary mr-2" style={{marginTop:'10px'}}>Add</button>
                                                            </div>
                                                        </div>
                                                    </form>
                                                </div>
                                            </div> */}
                                            {/* Add role end */}
                                            {/* Edit role start */}
                                            <div className="modalStyle" style={modalEditStyle}>
                                                <div className="modalContentStyle" style={{ maxHeight: '680px', overflowY: 'auto' }}>
                                                    <span onClick={closeEditModal} style={{ float: 'right', cursor: 'pointer', fontSize:'30px' }}>&times;</span>
                                                    <form className="pt-3" onSubmit={editUserRole}>
                                                        <div className="card-body">
                                                            <div style={{textAlign:'center'}}>
                                                                <h4 className="card-title">Edit Role's</h4>
                                                            </div>
                                                            <div className="table-responsive pt-3">
                                                                <div className="input-group">
                                                                    <div className="input-group-prepend">
                                                                        <span className="input-group-text" style={{color:'black', width:'125px'}}>Role Name</span>
                                                                    </div>
                                                                    <input type="text" className="form-control" placeholder="Role Name" value={roleEditname} maxLength={25} onChange={(e) => {const value = e.target.value; const sanitizedValue = value.replace(/[^a-zA-Z0-9 ]/g, ''); setEdituserRole(sanitizedValue);}} required/>
                                                                </div>
                                                            </div>
                                                            <div style={{textAlign:'center'}}>
                                                                <button type="submit" className="btn btn-primary mr-2" style={{marginTop:'10px'}} disabled={roleEditname === initialRoleEditname}>Update</button>
                                                            </div>
                                                        </div>
                                                    </form>
                                                </div>
                                            </div>
                                            {/* Edit role end */}
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
                                                        <h4 className="card-title" style={{paddingTop:'10px'}}>List Of Role's</h4>  
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
                                        <div className="table-responsive" style={{ maxHeight: '500px', overflowY: 'auto' }}>
                                            <table className="table table-striped">
                                                <thead style={{ textAlign: 'center', position: theadsticky, tableLayout: theadfixed, top: 0, zIndex: 1, backgroundColor: theadBackgroundColor}}>
                                                    <tr> 
                                                        <th>Sl.No</th>
                                                        <th>Role Name</th>
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
                                                                <td>{dataItem.role_name ? dataItem.role_name : '-'}</td>
                                                                <td>{dataItem.created_by ? dataItem.created_by : '-'}</td>
                                                                <td>{dataItem.created_date ? formatTimestamp(dataItem.created_date) : '-'}</td>
                                                                <td>{dataItem.modified_by ? dataItem.modified_by : '-'}</td>
                                                                <td>{dataItem.modified_date ?  formatTimestamp(dataItem.modified_date) : '-'}</td>
                                                                <td>{dataItem.status===true ? <span className="text-success">Active</span> : <span className="text-danger">DeActive</span>}</td>
                                                                <td>
                                                                    <div className='form-group' style={{paddingTop:'13px'}}> 
                                                                        {dataItem.status===true ?
                                                                            <div className="form-check form-check-danger">
                                                                                <label className="form-check-label"><input type="radio" className="form-check-input" name="optionsRadios1" id="optionsRadios2" value={false} onClick={(e) => changeDeActivate(e, dataItem.role_id)}/>DeActive<i className="input-helper"></i></label>
                                                                            </div>
                                                                        :
                                                                            <div className="form-check form-check-success">
                                                                                <label className="form-check-label"><input type="radio" className="form-check-input" name="optionsRadios1" id="optionsRadios1" value={true} onClick={(e) => changeActivate(e, dataItem.role_id)}/>Active<i className="input-helper"></i></label>
                                                                            </div>
                                                                        }
                                                                    </div>
                                                                </td>
                                                                <td>
                                                                    <button type="button" className="btn btn-outline-primary btn-icon-text"  onClick={() => handleEditUserAndToggleBackground(dataItem)} style={{marginBottom:'10px', marginRight:'10px'}}><i className="mdi mdi-pencil btn-icon-prepend"></i>Edit</button><br/>
                                                                </td>                                                    
                                                            </tr>
                                                        ))
                                                        ) : (
                                                        <tr>
                                                            <td colSpan="9" style={{ marginTop: '50px', textAlign: 'center' }}>No devices found</td>
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
                 
export default ManageUserRole