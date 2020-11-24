 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
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

 

 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

 

 
contract PartialERC20 is ERC20 {
    
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;

    uint256 internal _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
         
         
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
        value);
        _burn(account, value);
    }
}

 

   


contract PrivateToken is PartialERC20, Ownable {
    
    bool public isFreezed = false;
    
    address[] public holders;
    mapping(address => uint32) indexOfHolders;

    event Freezed(address commander);
    event RecordNewTokenHolder(address holder);
    event RemoveTokenHolder(address holder);
    
    function numberOfTokenHolders() public view returns(uint32) {
        return uint32(holders.length);
    }

    function isTokenHolder(address addr) public view returns(bool) {
        return indexOfHolders[addr] > 0;        
    }

    modifier isNotFreezed() {
        require(!isFreezed);
        _;
    }

    function freeze() public onlyOwner {
        isFreezed = true;

        emit Freezed(msg.sender);
    }

    function _recordNewTokenHolder(address holder) internal {
         
        if (!isTokenHolder(holder)) {
            holders.push(holder);
            indexOfHolders[holder] = uint32(holders.length);
            
            emit RecordNewTokenHolder(holder);
        }
    }

    function _removeTokenHolder(address holder) internal {
         
        if (isTokenHolder(holder)) {

             
            uint32 index = indexOfHolders[holder] - 1;

            if (holders.length > 1 && index != uint32(holders.length - 1)) {
                 
                address lastHolder = holders[holders.length - 1];
                holders[holders.length - 1] = holders[index];
                holders[index] = lastHolder;
                
                indexOfHolders[lastHolder] = indexOfHolders[holder];
            }
            holders.length--;
            indexOfHolders[holder] = 0;
            
            emit RemoveTokenHolder(holder);
        }
    }

     
    function transfer(address to, uint256 value) 
        public 
        isNotFreezed
        returns (bool) {

        _transfer(msg.sender, to, value);

         
        _recordNewTokenHolder(to);

        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) 
        public 
        isNotFreezed
        returns (bool) {

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        
         
        _recordNewTokenHolder(to);
        
        return true;
    }
}

 

 
contract KTFForTestMigration is PartialERC20, Ownable {
     
    string public name;  
    string public symbol;  
    uint32 public decimals; 

    PrivateToken public pktf;

    uint32 public holderCount;

    constructor(PrivateToken _pktf) public {  
        symbol = "KTF";  
        name = "Katinrun Foundation";  
        decimals = 18;  
        _totalSupply = 0;
        
        _balances[msg.sender] = _totalSupply;  

        pktf = _pktf;
    }

    function migrateFromPKTF()
        public
        onlyOwner {

        uint32 numberOfPKTFHolders = pktf.numberOfTokenHolders();
        holderCount = numberOfPKTFHolders;
        
        for(uint256 i = 0; i < numberOfPKTFHolders; i++) {
          address user = pktf.holders(i);
          uint256 balance = pktf.balanceOf(user);

          mint(user, balance);
        }
    }

     
    function mint(address to,uint256 value) 
        public
        onlyOwner
        returns (bool)
    {
        _mint(to, value);

        return true;
    }
}

 

contract MintableWithVoucher is PrivateToken {
    mapping(uint64 => bool) usedVouchers;
    mapping(bytes32 => uint32) holderRedemptionCount;
    
    event VoucherUsed(
        uint64 voucherID,
        uint64 parityCode, 
        uint256 amount,  
        uint256 expired,  
        address indexed receiver,  
        bytes32 socialHash
    );

    function isVoucherUsed(uint64 _voucherID) public view returns (bool) {
        return usedVouchers[_voucherID];
    }
    
    function markVoucherAsUsed(uint64 _voucherID) private {
        usedVouchers[_voucherID] = true;
    }

    function getHolderRedemptionCount(bytes32 socialHash) public view returns(uint32) {
        return holderRedemptionCount[socialHash];
    }

    function isVoucherExpired(uint256 expired) public view returns(bool) {
        return expired < now;
    }

    function expireTomorrow() public view returns (uint256) {
        return now + 1 days;
    }

    function expireNow() public view returns (uint256) {
        return now;
    }

     
     
    function redeemVoucher(
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s,
        uint64 _voucherID,
        uint64 _parityCode,
        uint256 _amount,
        uint256 _expired,
        address _receiver,
        bytes32 _socialHash
    )  
    public 
    isNotFreezed
    {
        require(!isVoucherUsed(_voucherID), "Voucher has already been used.");
        require(!isVoucherExpired(_expired), "Voucher is expired.");

        bytes memory prefix = "\x19Ethereum Signed Message:\n80";
        bytes memory encoded = abi.encodePacked(prefix,_voucherID, _parityCode, _amount, _expired);

        require(ecrecover(keccak256(encoded), _v, _r, _s) == owner());

         
        _mint(_receiver, _amount * 10 ** 18);

         
        _recordNewTokenHolder(_receiver);

        markVoucherAsUsed(_voucherID);

        holderRedemptionCount[_socialHash]++;

        emit VoucherUsed(_voucherID, _parityCode, _amount,  _expired, _receiver, _socialHash);
    }
    
     
    function mint(address to,uint256 value) 
        public
        onlyOwner  
        isNotFreezed
        returns (bool)
    {
        _mint(to, value);

         
        _recordNewTokenHolder(to);

        return true;
    }

     
    function burn(uint256 value) 
        public
        onlyOwner
        isNotFreezed {

        _burn(msg.sender, value);
         
    }

     
    function burn(address account, uint256 value) 
        public
        onlyOwner
        isNotFreezed {

        _burn(account, value);
         
    }

     
    function burnFrom(address account, uint256 value) 
        public 
        isNotFreezed 
        {
        require(account != address(0));

        _burnFrom(account, value);

         
         
         
    }
}

 

contract PrivateKatinrunFoudation is MintableWithVoucher {
     
    string public name;  
    string public symbol;  
    uint32 public decimals; 

    PrivateToken public pktf;
    uint32 public holderCount;

    constructor(PrivateToken _pktf) public {  
        symbol = "PKTF";  
        name = "Private Katinrun Foundation";  
        decimals = 18;  
        _totalSupply = 0;  
        
        _balances[msg.sender] = _totalSupply;  

        if(_pktf != address(0)){
            pktf = _pktf;
            uint32 numberOfPKTFHolders = pktf.numberOfTokenHolders();
            holderCount = numberOfPKTFHolders;
            
            for(uint256 i = 0; i < numberOfPKTFHolders; i++) {
                address user = pktf.holders(i);
                uint256 balance = pktf.balanceOf(user);

                mint(user, balance);
            }
        }
        
         
    }
    
}