 

pragma solidity ^0.4.25;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
contract ERC20MOVEInterface {
    function balanceOf(address owner) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function burnFrom(address from, uint256 value) public;
}

 
contract CO2Certificate {
    using SafeMath for uint256;

    uint256 private _burnedTokens;
    uint256 private _certifiedKilometers;
    string  private _ownerName;

    constructor (uint256 burnedTokens, uint256 certifiedKilometers, string ownerName) public {
        require (burnedTokens > 0, "You must burn at least one token");
        require (certifiedKilometers >= 0, "Certified Kilometers must be positive");
        
        _burnedTokens = burnedTokens;
        _certifiedKilometers = certifiedKilometers;
        _ownerName = ownerName;
    }

     
    function getBurnedTokens() public view returns(uint256) {
        return _burnedTokens;
    }

    function getCertifiedKilometers() public view returns(uint256) {
        return _certifiedKilometers;
    }

    function getOwnerName() public view returns(string) {
        return _ownerName;
    }

}

 
contract MovecoinCertificationAuthority {
    using SafeMath for uint256;

     
    mapping (address => address) private _certificates;
    
     
    address private _owner;
    address private _moveAddress;

     
    event certificateIssued(uint256 tokens, uint256 kilometers, string ownerName, address certificateAddress);

    modifier onlymanager()
    {
        require(msg.sender == _owner, "Only Manager can access this function");
        _;
    }

     
    constructor (address moveAddress) public {
        require(moveAddress != address(0), "MOVE ERC20 Address cannot be null");
        _owner = msg.sender;
        _moveAddress = moveAddress;
    }

     
    function transferManager(address newManager) public onlymanager {
        require(newManager != address(0), "Manager cannot be null");
        _owner = newManager;
    }

     
    function getCertificateAddress(address certOwner) public view returns (address) {
        require(certOwner != address(0), "Certificate owner cannot be null");
        return _certificates[certOwner];
    } 

     
    function getCertificateData(address certOwner) public view returns (uint256, uint256, string) {
        require(certOwner != address(0), "Certificate owner cannot be null");

        CO2Certificate cert = CO2Certificate(_certificates[certOwner]);

        return (
            cert.getBurnedTokens(),
            cert.getCertifiedKilometers(),
            cert.getOwnerName()
        );
    }

     
    function issueNewCertificate(
        address certificateReceiver,
        uint256 tokensToBurn, 
        uint256 kilomitersToCertify, 
        string certificateReceiverName
    ) public onlymanager {

         
        ERC20MOVEInterface movecoin = ERC20MOVEInterface(_moveAddress);

         
        require(tokensToBurn <= movecoin.balanceOf(certificateReceiver), "Certificate receiver must have tokens");

         
        require(
            tokensToBurn <= movecoin.allowance(certificateReceiver, this),
            "CO2 Contract is not allowed to burn tokens in behalf of certificate receiver"
        );

         
        movecoin.burnFrom(certificateReceiver, tokensToBurn);

         
        address Certificate = new CO2Certificate(tokensToBurn, kilomitersToCertify, certificateReceiverName);
        _certificates[certificateReceiver] = Certificate;

        emit certificateIssued(tokensToBurn, kilomitersToCertify, certificateReceiverName, Certificate);
    }

}