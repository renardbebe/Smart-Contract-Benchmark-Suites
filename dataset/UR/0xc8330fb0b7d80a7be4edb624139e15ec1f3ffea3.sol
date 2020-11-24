 

 
pragma solidity ^0.4.19;


 
 
 
 
 
 
 
 
 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

     
    function Owned() public {
        owner = msg.sender;
    }

     
     
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
     
     
     
     
     
     
    function proposeOwnership(address _newOwnerCandidate) public onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
     
    function acceptOwnership() public {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

     
     
     
     
    function changeOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

     
     
     
     
     
    function removeOwnership(address _dac) public onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        OwnershipRemoved();     
    }
} 
 
pragma solidity ^0.4.19;


 
contract ERC20 {
  
     
    function totalSupply() public constant returns (uint256 supply);

     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}
 
pragma solidity ^0.4.19;
 





 
 
 
 
 
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist;  

     
     
     
     
     
     
     
     
     
     
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) public {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

     
     
    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

     
     
     
     
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        EscapeHatchBlackistedToken(_token);
    }

     
     
     
     
    function isTokenEscapable(address _token) view public returns (bool) {
        return !escapeBlacklist[_token];
    }

     
     
     
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

         
        if (_token == 0x0) {
            balance = this.balance;
            escapeHatchDestination.transfer(balance);
            EscapeHatchCalled(_token, balance);
            return;
        }
         
        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        require(token.transfer(escapeHatchDestination, balance));
        EscapeHatchCalled(_token, balance);
    }

     
     
     
     
     
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}
 
pragma solidity ^0.4.19;

 

 
 
 
 




contract DAppNodePackageDirectory is Owned,Escapable {

    enum DAppNodePackageStatus {Preparing, Develop, Active, Deprecated, Deleted}

    struct DAppNodePackage {
        string name;
        DAppNodePackageStatus status;
    }

    DAppNodePackage[] DAppNodePackages;

    event PackageAdded(uint indexed idPackage, string name);
    event PackageUpdated(uint indexed idPackage, string name);
    event StatusChanged(uint idPackage, DAppNodePackageStatus newStatus);

     
     
     
     
     
     
     
     
     
     
    function DAppNodePackageDirectory(
        address _escapeHatchCaller,
        address _escapeHatchDestination
    ) 
        Escapable(_escapeHatchCaller, _escapeHatchDestination)
        public
    {
    }

     
     
     
    function addPackage (
        string name
    ) onlyOwner public returns(uint idPackage) {
        idPackage = DAppNodePackages.length++;
        DAppNodePackage storage c = DAppNodePackages[idPackage];
        c.name = name;
         
        PackageAdded(idPackage,name);
    }

     
     
     
    function updatePackage (
        uint idPackage,
        string name
    ) onlyOwner public {
        require(idPackage < DAppNodePackages.length);
        DAppNodePackage storage c = DAppNodePackages[idPackage];
        c.name = name;
         
        PackageUpdated(idPackage,name);
    }

     
     
     
    function changeStatus(
        uint idPackage,
        DAppNodePackageStatus newStatus
    ) onlyOwner public {
        require(idPackage < DAppNodePackages.length);
        DAppNodePackage storage c = DAppNodePackages[idPackage];
        c.status = newStatus;
         
        StatusChanged(idPackage, newStatus);
    }

     
     
     
     
    function getPackage(uint idPackage) constant public returns (
        string name,
        DAppNodePackageStatus status
    ) {
        require(idPackage < DAppNodePackages.length);
        DAppNodePackage storage c = DAppNodePackages[idPackage];
        name = c.name;
        status = c.status;
    }

     
     
    function numberOfDAppNodePackages() view public returns (uint) {
        return DAppNodePackages.length;
    }
}