 

pragma solidity ^0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
pragma solidity ^0.4.24;



 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
pragma solidity ^0.4.24;

 
contract RivetzRegistrar is Ownable {
    using SafeMath for uint256;

    struct SPEntry {
         
        address registrant;
         
        address admin;
         
        uint256 pubKeyHash;
         
        uint256 infoHash;
         
        uint256  expiration;
         
        bool    valid;
    }

     
    event SPCreated(uint256 indexed spid);

    mapping(uint256 => SPEntry) public spEntries;

     
    ERC20 public rvt;
     
    address public paymentWalletAddress;
     

     
    uint64 constant secPerYear = 365 days;   

     
    uint256 public registrationFee = 1000 ether;                
     
    uint256 constant defaultAnnualFee = 1000 ether;      
     
    uint256 public feePerSec = defaultAnnualFee / secPerYear;   


     
    constructor(address paymentTokenAddress, address paymentDestAddress) public {
        rvt = ERC20(paymentTokenAddress);
        paymentWalletAddress = paymentDestAddress;
    }

     
    function register(uint256 spid, uint256 pubKeyHash, uint256 infoHash) public {
        require(rvt.transferFrom(msg.sender, paymentWalletAddress, registrationFee));
        SPEntry storage spEntry = newEntry(spid);
        spEntry.registrant = msg.sender;
        spEntry.admin = msg.sender;
        spEntry.pubKeyHash = pubKeyHash;
        spEntry.infoHash = infoHash;
        spEntry.valid = false;
    }

     
    function rivetzRegister(uint256 spid, uint256 pubKeyHash, uint256 infoHash, address spidRegistrant, address spidAdmin) onlyOwner public {
        SPEntry storage spEntry = newEntry(spid);
        spEntry.registrant = spidRegistrant;
        spEntry.admin = spidAdmin;
        spEntry.pubKeyHash = pubKeyHash;
        spEntry.infoHash = infoHash;
        spEntry.valid = true;
    }

     
    function newEntry(uint256 spid) internal returns (SPEntry storage) {
        SPEntry storage spEntry = spEntries[spid];
        require(spEntry.registrant == 0);
        spEntry.expiration = now + secPerYear;
        emit SPCreated(spid);
        return spEntry;
    }

     
    function setRegistrant(uint256 spid, address registrant) public {
        SPEntry storage spEntry = spEntries[spid];
        require(spEntry.registrant != 0 && spEntry.registrant != address(0x1) );
        requireRegistrantOrGreater(spEntry);
        spEntry.registrant = registrant;
    }

     
    function setAdmin(uint256 spid, address admin) public {
        SPEntry storage spEntry = spEntries[spid];
        requireRegistrantOrGreater(spEntry);
        spEntry.admin = admin;
    }

     
    function setPubKey(uint256 spid, uint256 pubKeyHash) public {
        SPEntry storage spEntry = spEntries[spid];
        requireRegistrantOrGreater(spEntry);
        spEntry.pubKeyHash = pubKeyHash;
    }

     
    function setInfo(uint256 spid, uint256 infoHash) public {
        SPEntry storage spEntry = spEntries[spid];
        requireAdminOrGreater(spEntry);
        spEntry.infoHash = infoHash;
    }

     
    function setValid(uint256 spid, bool valid) onlyOwner public {
        spEntries[spid].valid = valid;
    }

     
    function renew(uint256 spid, uint256 payment) public returns (uint256 expiration) {
        SPEntry storage spEntry = spEntries[spid];
        require(rvt.transferFrom(msg.sender, paymentWalletAddress, payment));
        uint256 periodStart = (spEntry.expiration > now) ? spEntry.expiration : now;
        spEntry.expiration = periodStart.add(feeToSeconds(payment));
        return spEntry.expiration;
    }

     
    function setExpiration(uint256 spid, uint256 expiration) onlyOwner public {
        spEntries[spid].expiration = expiration;
    }

     
    function release(uint256 spid) public {
        SPEntry storage spEntry = spEntries[spid];
        requireRegistrantOrGreater(spEntry);
        spEntry.expiration = 0;
        spEntry.registrant = address(0x1);
        spEntry.admin = address(0x1);
        spEntry.valid = false;
    }

     
    function rivetzRelease(uint256 spid) onlyOwner public {
        SPEntry storage spEntry = spEntries[spid];
        spEntry.registrant = address(0x1);
        spEntry.admin = address(0x1);
        spEntry.pubKeyHash = 0;
        spEntry.infoHash = 0;
        spEntry.expiration = 0;
        spEntry.valid = false;
    }

     
    function setFees(uint256 newRegistrationFee, uint256 newAnnualFee) onlyOwner public {
        registrationFee = newRegistrationFee;
        feePerSec = newAnnualFee / secPerYear;
    }


     
    function setToken(address erc20Address) onlyOwner public {
        rvt = ERC20(erc20Address);
    }

     
    function setPaymentAddress(address paymentAddress) onlyOwner public {
        paymentWalletAddress = paymentAddress;
    }

     
    function requireAdminOrGreater(SPEntry spEntry) internal view {
        require (msg.sender == spEntry.admin ||
                 msg.sender == spEntry.registrant ||
                 msg.sender == owner);
        require (isSubscribed(spEntry) || msg.sender == owner);
    }

     
    function requireRegistrantOrGreater(SPEntry spEntry) internal view  {
        require (msg.sender == spEntry.registrant ||
                 msg.sender == owner);
        require (isSubscribed(spEntry) || msg.sender == owner);
    }

     
    function getAnnualFee() public view returns (uint256) {
        return feePerSec.mul(secPerYear);
    }

     
    function feeToSeconds(uint256 feeAmount) internal view returns (uint256 seconds_)
    {
        return feeAmount / feePerSec;                    
    }

    function isSubscribed(SPEntry spEntry) internal view returns (bool subscribed)
    {
        return now < spEntry.expiration;
    }
}