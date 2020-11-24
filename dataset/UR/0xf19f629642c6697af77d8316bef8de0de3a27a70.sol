 

pragma solidity ^0.5.10;

 
 
 
 
 
 
 
 
 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

     
    constructor() public {
        owner = msg.sender;
    }

     
     
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
     
     
     
     
     
     
    function proposeOwnership(address _newOwnerCandidate) public onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        emit OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
     
    function acceptOwnership() public {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = address(0);

        emit OwnershipTransferred(oldOwner, owner);
    }

     
     
     
     
    function changeOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = address(0);

        emit OwnershipTransferred(oldOwner, owner);
    }

     
     
     
     
     
    function removeOwnership(address _dac) public onlyOwner {
        require(_dac == address(0xdAc0000000000000000000000000000000000000));
        owner = address(0);
        newOwnerCandidate = address(0);
        emit OwnershipRemoved();     
    }
} 

 
 
 
 
 
contract Escapable is Owned {
    address public escapeHatchCaller;
    address payable public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist;  

     
     
     
     
     
     
     
     
     
     
    constructor(address _escapeHatchCaller, address payable _escapeHatchDestination) public {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

     
     
    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

     
     
     
     
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        emit EscapeHatchBlackistedToken(_token);
    }

     
     
     
     
    function isTokenEscapable(address _token) view public returns (bool) {
        return !escapeBlacklist[_token];
    }

     
     
     
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

         
        if (_token == address(0)) {
            balance = address(this).balance;
            escapeHatchDestination.transfer(balance);
            emit EscapeHatchCalled(_token, balance);
            return;
        }
         
        ERC20 token = ERC20(_token);
        balance = token.balanceOf(address(this));
        require(token.transfer(escapeHatchDestination, balance));
        emit EscapeHatchCalled(_token, balance);
    }

     
     
     
     
     
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}


 

 
 
 
 

contract DAppNodePackageDirectory is Owned,Escapable {

     
     
     
     
    struct DAppNodePackage {
        uint128 position;
        uint128 status;
        string name;
    }

    bytes32 public featured;
    DAppNodePackage[] DAppNodePackages;

    event PackageAdded(uint indexed idPackage, string name);
    event PackageUpdated(uint indexed idPackage, string name);
    event StatusChanged(uint idPackage, uint128 newStatus);
    event PositionChanged(uint idPackage, uint128 newPosition);
    event FeaturedChanged(bytes32 newFeatured);

     
     
     
     
     
     
     
     
     
     
    constructor(
        address _escapeHatchCaller,
        address payable _escapeHatchDestination
    ) 
        Escapable(_escapeHatchCaller, _escapeHatchDestination)
        public
    {
    }

     
     
     
     
     
    function addPackage (
        string memory name,
        uint128 status,
        uint128 position
    ) public onlyOwner returns(uint idPackage) {
        idPackage = DAppNodePackages.length++;
        DAppNodePackage storage c = DAppNodePackages[idPackage];
        c.name = name;
        if (position == 0) {
            c.position = uint128(1000 * (idPackage + 1));
        } else {
            c.position = position;
        }
        c.status = status;
         
        emit PackageAdded(idPackage, name);
    }

     
     
     
     
     
    function updatePackage (
        uint idPackage,
        string memory name,
        uint128 status,
        uint128 position
    ) public onlyOwner {
        require(idPackage < DAppNodePackages.length);
        DAppNodePackage storage c = DAppNodePackages[idPackage];
        c.name = name;
        c.position = position;
        c.status = status;
         
        emit PackageUpdated(idPackage, name);
    }

     
     
     
    function changeStatus(
        uint idPackage,
        uint128 newStatus
    ) public onlyOwner {
        require(idPackage < DAppNodePackages.length);
        DAppNodePackage storage c = DAppNodePackages[idPackage];
        c.status = newStatus;
        emit StatusChanged(idPackage, newStatus);
    }

     
     
     
    function changePosition(
        uint idPackage,
        uint128 newPosition
    ) public onlyOwner {
        require(idPackage < DAppNodePackages.length);
        DAppNodePackage storage c = DAppNodePackages[idPackage];
        c.position = newPosition;
        emit PositionChanged(idPackage, newPosition);
    }
    
    
     
     
     
    function switchPosition(
        uint idPackage1,
        uint idPackage2
    ) public onlyOwner {
        require(idPackage1 < DAppNodePackages.length);
        require(idPackage2 < DAppNodePackages.length);

        DAppNodePackage storage p1 = DAppNodePackages[idPackage1];
        DAppNodePackage storage p2 = DAppNodePackages[idPackage2];
        
        uint128 tmp = p1.position;
        p1.position = p2.position;
        p2.position = tmp;
        emit PositionChanged(idPackage1, p1.position);
        emit PositionChanged(idPackage2, p2.position);

    }

     
     
     
    function changeFeatured(
        bytes32 _featured
    ) public onlyOwner {
        featured = _featured;
        emit FeaturedChanged(_featured);
    }

     
     
     
     
    function getPackage(uint idPackage) public view returns (
        string memory name,
        uint128 status,
        uint128 position
    ) {
        require(idPackage < DAppNodePackages.length);
        DAppNodePackage storage c = DAppNodePackages[idPackage];
        name = c.name;
        status = c.status;
        position = c.position;
    }

     
     
    function numberOfDAppNodePackages() view public returns (uint) {
        return DAppNodePackages.length;
    }
}

 








 
contract ERC20 {
  
     
    function totalSupply() public view returns (uint256 supply);

     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}