 

 
 
contract Osler_SmartContracts_Demo_Certificate_of_Attendance {
  address public owner = msg.sender;
  string certificate;

  function publishLawyersInAttendance(string cert) {

    if (msg.sender !=owner){
       
      revert();
    }
    certificate = cert;
  }
  function showCertificate() constant returns (string) {
    return certificate;
  }
}