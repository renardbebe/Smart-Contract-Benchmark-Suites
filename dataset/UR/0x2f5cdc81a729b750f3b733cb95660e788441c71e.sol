 

pragma solidity ^0.4.19;

 

 
contract RocketStorageInterface {
     
    modifier onlyLatestRocketNetworkContract() {_;}
     
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string);
    function getBytes(bytes32 _key) external view returns (bytes);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
     
    function setAddress(bytes32 _key, address _value) onlyLatestRocketNetworkContract external;
    function setUint(bytes32 _key, uint _value) onlyLatestRocketNetworkContract external;
    function setString(bytes32 _key, string _value) onlyLatestRocketNetworkContract external;
    function setBytes(bytes32 _key, bytes _value) onlyLatestRocketNetworkContract external;
    function setBool(bytes32 _key, bool _value) onlyLatestRocketNetworkContract external;
    function setInt(bytes32 _key, int _value) onlyLatestRocketNetworkContract external;
     
    function deleteAddress(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteUint(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteString(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteBytes(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteBool(bytes32 _key) onlyLatestRocketNetworkContract external;
    function deleteInt(bytes32 _key) onlyLatestRocketNetworkContract external;
     
    function kcck256str(string _key1) external pure returns (bytes32);
    function kcck256strstr(string _key1, string _key2) external pure returns (bytes32);
    function kcck256stradd(string _key1, address _key2) external pure returns (bytes32);
    function kcck256straddadd(string _key1, address _key2, address _key3) external pure returns (bytes32);
}

 

 
 
contract RocketBase {

     

    event ContractAdded (
        address indexed _newContractAddress,                     
        uint256 created                                          
    );

    event ContractUpgraded (
        address indexed _oldContractAddress,                     
        address indexed _newContractAddress,                     
        uint256 created                                          
    );

     

    uint8 public version;                                                    


     

    RocketStorageInterface rocketStorage = RocketStorageInterface(0);        


     

     
    modifier onlyOwner() {
        roleCheck("owner", msg.sender);
        _;
    }

     
    modifier onlyAdmin() {
        roleCheck("admin", msg.sender);
        _;
    }

     
    modifier onlySuperUser() {
        require(roleHas("owner", msg.sender) || roleHas("admin", msg.sender));
        _;
    }

     
    modifier onlyRole(string _role) {
        roleCheck(_role, msg.sender);
        _;
    }

  
     
   
     
    constructor(address _rocketStorageAddress) public {
         
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
    }


     

     
    function isOwner(address _address) public view returns (bool) {
        return rocketStorage.getBool(keccak256("access.role", "owner", _address));
    }

     
    function roleHas(string _role, address _address) internal view returns (bool) {
        return rocketStorage.getBool(keccak256("access.role", _role, _address));
    }

      
    function roleCheck(string _role, address _address) view internal {
        require(roleHas(_role, _address) == true);
    }

}

 

 
contract Authorized is RocketBase {

     
     
     

     
     
     

     
     
     

    event IssuerTransferred(address indexed previousIssuer, address indexed newIssuer);
    event AuditorTransferred(address indexed previousAuditor, address indexed newAuditor);
    event DepositoryTransferred(address indexed previousDepository, address indexed newDepository);

     

     
    modifier onlyIssuer {
        require( msg.sender == issuer() );
        _;
    }

     
    modifier onlyDepository {
        require( msg.sender == depository() );
        _;
    }

     
    modifier onlyAuditor {
        require( msg.sender == auditor() );
        _;
    }


   
  function setIssuer(address newIssuer) public onlyOwner {
    require(newIssuer != address(0));
    rocketStorage.setAddress(keccak256("token.issuer"), newIssuer);
    emit IssuerTransferred(issuer(), newIssuer);
  }

   
  function issuer() public view returns (address) {
    return rocketStorage.getAddress(keccak256("token.issuer"));
  }

   
  function setAuditor(address newAuditor) public onlyOwner {
    require(newAuditor != address(0));
    rocketStorage.setAddress(keccak256("token.auditor"), newAuditor);
    emit AuditorTransferred(auditor(), newAuditor);
  }

   
  function auditor() public view returns (address) {
    return rocketStorage.getAddress(keccak256("token.auditor"));
  }

   
  function setDepository(address newDepository) public onlyOwner {
    require(newDepository != address(0));
    rocketStorage.setAddress(keccak256("token.depository"), newDepository);
    emit DepositoryTransferred(depository(), newDepository);
  }

   
  function depository() public view returns (address) {
    return rocketStorage.getAddress(keccak256("token.depository"));
  }

}

 

 
contract PausableRedemption is RocketBase {
  event PauseRedemption();
  event UnpauseRedemption();

   
   
   

   
  modifier whenRedemptionNotPaused() {
    require(!redemptionPaused());
    _;
  }

   
  modifier whenRedemptionPaused() {
    require(redemptionPaused());
    _;
  }

   
  function redemptionPaused() public view returns (bool) {
    return rocketStorage.getBool(keccak256("token.redemptionPaused"));
  }

   
  function pauseRedemption() onlyOwner whenRedemptionNotPaused public {
    rocketStorage.setBool(keccak256("token.redemptionPaused"), true);
    emit PauseRedemption();
  }

   
  function unpauseRedemption() onlyOwner whenRedemptionPaused public {
    rocketStorage.setBool(keccak256("token.redemptionPaused"), false);
    emit UnpauseRedemption();
  }
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

contract Issuable is RocketBase, Authorized, PausableRedemption {
    using SafeMath for uint256;

    event AssetsUpdated(address indexed depository, uint256 amount);
    event CertificationUpdated(address indexed auditor, uint256 amount);

     
    function assetsOnDeposit() public view returns (uint256) {
        return rocketStorage.getUint(keccak256("issuable.assetsOnDeposit"));
    }

     
    function assetsCertified() public view returns (uint256) {
        return rocketStorage.getUint(keccak256("issuable.assetsCertified"));
    }

     

     
    function setAssetsOnDeposit(uint256 _total) public onlyDepository whenRedemptionPaused {
        uint256 totalSupply_ = rocketStorage.getUint(keccak256("token.totalSupply"));
        require(_total >= totalSupply_);
        rocketStorage.setUint(keccak256("issuable.assetsOnDeposit"), _total);
        emit AssetsUpdated(msg.sender, _total);
    }

     
    function setAssetsCertified(uint256 _total) public onlyAuditor whenRedemptionPaused {
        uint256 totalSupply_ = rocketStorage.getUint(keccak256("token.totalSupply"));
        require(_total >= totalSupply_);
        rocketStorage.setUint(keccak256("issuable.assetsCertified"), _total);
        emit CertificationUpdated(msg.sender, _total);
    }

     

     
    function receiveAssets(uint256 _units) public onlyDepository {
        uint256 total_ = assetsOnDeposit().add(_units);
        rocketStorage.setUint(keccak256("issuable.assetsOnDeposit"), total_);
        emit AssetsUpdated(msg.sender, total_);
    }

     
    function releaseAssets(uint256 _units) public onlyDepository {
        uint256 totalSupply_ = rocketStorage.getUint(keccak256("token.totalSupply"));
        uint256 total_ = assetsOnDeposit().sub(_units);
        require(total_ >= totalSupply_);
        rocketStorage.setUint(keccak256("issuable.assetsOnDeposit"), total_);
        emit AssetsUpdated(msg.sender, total_);
    }

     
    function increaseAssetsCertified(uint256 _units) public onlyAuditor {
        uint256 total_ = assetsCertified().add(_units);
        rocketStorage.setUint(keccak256("issuable.assetsCertified"), total_);
        emit CertificationUpdated(msg.sender, total_);
    }

     
    function decreaseAssetsCertified(uint256 _units) public onlyAuditor {
        uint256 totalSupply_ = rocketStorage.getUint(keccak256("token.totalSupply"));
        uint256 total_ = assetsCertified().sub(_units);
        require(total_ >= totalSupply_);
        rocketStorage.setUint(keccak256("issuable.assetsCertified"), total_);
        emit CertificationUpdated(msg.sender, total_);
    }

}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
 
contract LD2Token is ERC20, RocketBase, Issuable {
  using SafeMath for uint256;

  event TokensIssued(address indexed issuer, uint256 amount);

   
   

   
   

   
   
   

   
  function totalSupply() public view returns (uint256) {
    return rocketStorage.getUint(keccak256("token.totalSupply"));
  }

   
  function increaseTotalSupply(uint256 _increase) internal {
    uint256 totalSupply_ = totalSupply();
    totalSupply_ = totalSupply_.add(_increase);
    rocketStorage.setUint(keccak256("token.totalSupply"),totalSupply_);
  }

   
  function decreaseTotalSupply(uint256 _decrease) internal {
    uint256 totalSupply_ = totalSupply();
    totalSupply_ = totalSupply_.sub(_decrease);
    rocketStorage.setUint(keccak256("token.totalSupply"),totalSupply_);
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balanceOf(msg.sender));

     
     
    setBalanceOf(msg.sender, balanceOf(msg.sender).sub(_value));
    setBalanceOf(_to, balanceOf(_to).add(_value));
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return rocketStorage.getUint(keccak256("token.balances",_owner));
  }

   
  function setBalanceOf(address _owner, uint256 _balance) internal {
    rocketStorage.setUint(keccak256("token.balances",_owner), _balance);
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return rocketStorage.getUint(keccak256("token.allowed",_owner,_spender));
  }

   
  function setAllowance(address _owner, address _spender, uint256 _balance) internal {
    rocketStorage.setUint(keccak256("token.allowed",_owner,_spender), _balance);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balanceOf(_from));
    require(_value <= allowance(_from, msg.sender));
    
    setBalanceOf(_from, balanceOf(_from).sub(_value));
    setBalanceOf(_to, balanceOf(_to).add(_value));
    setAllowance(_from, msg.sender, allowance(_from, msg.sender).sub(_value));
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    setAllowance(msg.sender, _spender, _value);
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    setAllowance(msg.sender, _spender, allowance(msg.sender, _spender).add(_addedValue));
    emit Approval(msg.sender, _spender, allowance(msg.sender, _spender));
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowance(msg.sender, _spender);
    if (_subtractedValue > oldValue) {
      setAllowance(msg.sender, _spender, 0);
    } else {
      setAllowance(msg.sender, _spender, oldValue.sub(_subtractedValue));
    }
    emit Approval(msg.sender, _spender, allowance(msg.sender, _spender));
    return true;
  }


   
  function issueTokensForAssets( uint256 _units ) public onlyIssuer {

    uint256 newSupply_ = totalSupply().add(_units);

     
    uint256 limit_ = 0;
    if ( assetsOnDeposit() > assetsCertified() )
      limit_ = assetsOnDeposit();
    else
      limit_ = assetsCertified();

     
    require( newSupply_ <= limit_ );

     
    increaseTotalSupply( _units );

     
    setBalanceOf(issuer(), balanceOf(issuer()).add(_units));

    emit TokensIssued(issuer(), _units);
  }

}

 

 
 
contract LD2Zero is LD2Token {

  string public name = "LD2.zero";
  string public symbol = "XLDZ";
   
   

   

   
  constructor(address _rocketStorageAddress) RocketBase(_rocketStorageAddress) public {
     
    if(decimals() == 0) {
      rocketStorage.setUint(keccak256("token.decimals"),18);
    }
  }

  function decimals() public view returns (uint8) {
    return uint8(rocketStorage.getUint(keccak256("token.decimals")));
  }

}