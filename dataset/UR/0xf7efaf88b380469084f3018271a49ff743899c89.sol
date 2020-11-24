 

pragma solidity ^0.4.25;

 

library SafeMath256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if(a==0 || b==0)
        return 0;  
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b>0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
   require( b<= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
  
}


 
contract Ownable {

  mapping (address=>bool) owners;
  address owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AddOwner(address newOwner);
  event RemoveOwner(address owner);

   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
  }

  function isContract(address _addr) internal view returns(bool){
     uint256 length;
     assembly{
      length := extcodesize(_addr)
     }
     if(length > 0){
       return true;
    }
    else {
      return false;
    }

  }

  
  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner) public onlyOwner{
    require(isContract(newOwner) == false); 
    emit OwnershipTransferred(owner,newOwner);
    owner = newOwner;

  }

   
  modifier onlyOwners(){
    require(owners[msg.sender] == true);
    _;
  }

  function addOwner(address newOwner) public onlyOwners{
    require(owners[newOwner] == false);
    require(newOwner != msg.sender);

    owners[newOwner] = true;
    emit AddOwner(newOwner);
  }

  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender);   
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }

  function isOwner(address _owner) public view returns(bool){
    return owners[_owner];
  }
}

contract ERC20 {
       event Transfer(address indexed from, address indexed to, uint256 tokens);
       event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

       function totalSupply() public view returns (uint256);
       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

       function transfer(address to, uint256 tokens) public returns (bool success);
       
       function approve(address spender, uint256 tokens) public returns (bool success);
       function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
  

}


contract StandarERC20 is ERC20{
  using SafeMath256 for uint256; 
     
     mapping (address => uint256) balance;
     mapping (address => mapping (address=>uint256)) allowed;


     uint256  totalSupply_; 
     
      event Transfer(address indexed from,address indexed to,uint256 value);
      event Approval(address indexed owner,address indexed spender,uint256 value);


    function totalSupply() public view returns (uint256){
      return totalSupply_;
    }

     function balanceOf(address _walletAddress) public view returns (uint256){
        return balance[_walletAddress]; 
     }


     function allowance(address _owner, address _spender) public view returns (uint256){
          return allowed[_owner][_spender];
        }

     function transfer(address _to, uint256 _value) public returns (bool){
        require(_value <= balance[msg.sender]);
        require(_to != address(0));

        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);
        
        return true;

     }

     function approve(address _spender, uint256 _value)
            public returns (bool){
            allowed[msg.sender][_spender] = _value;

            emit Approval(msg.sender, _spender, _value);
            return true;
            }

      function transferFrom(address _from, address _to, uint256 _value)
            public returns (bool){
               require(_value <= balance[_from]);
               require(_value <= allowed[_from][msg.sender]); 
               require(_to != address(0));

              balance[_from] = balance[_from].sub(_value);
              balance[_to] = balance[_to].add(_value);
              allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
              emit Transfer(_from, _to, _value);
              return true;
      }


     
}


contract SGDS is StandarERC20, Ownable {
  using SafeMath256 for uint256;
  string public name = "SEITEE SGD";
  string public symbol = "SGDS"; 
  uint256 public decimals = 2;
  uint256 public totalUsed;
  uint256 public totalPurchange;
  uint256 public transFee = 100;  
  uint256 public version = 10000;
  
  
  struct PurchaseData{
    string fromCoin;    
    uint256 value;      
    uint256 exchangeRate;  
    string tranHash;   
  }

  event PurchaseSGDS(address indexed addr,uint256 value,uint256 refID);
  event UsedSGDS(address indexed addr,uint256 value);
  event SetControlToken(address indexed addr, bool outControl);
  event FeeTransfer(address indexed addr,uint256 _value);
  event TransferWallet(address indexed from,address indexed to,address indexed execute_);

  mapping(address => bool) userControl;    
  mapping(uint256 => uint256) purchaseID;

  PurchaseData[]  purDatas;

  constructor() public {
    totalSupply_ = 0;
    totalUsed = 0;
    totalPurchange = 0;
  }

 
  function purchaseSGDS(address addr, uint256 value,uint256 refID,string fromCoin,uint256 coinValue,uint256 rate,string txHash)  external onlyOwners{
    balance[addr] += value;
    totalSupply_ += value;
    totalPurchange += value;
    
    uint256 id = purDatas.push(PurchaseData(fromCoin,coinValue,rate,txHash));
    purchaseID[refID] = id;

    emit PurchaseSGDS(addr,value,refID);
    emit Transfer(address(this),addr,value);
  }

  function getPurchaseData(uint256 refID) view public returns(string fromCoin,uint256 value,uint256 exchangeRate,string txHash) {
    require(purchaseID[refID] > 0);
    uint256  pId = purchaseID[refID] - 1;
    PurchaseData memory pData = purDatas[pId];

    fromCoin = pData.fromCoin;
    value = pData.value;
    exchangeRate = pData.exchangeRate;
    txHash = pData.tranHash;

  }

 
 
  function useSGDS(address useAddr,uint256 value) onlyOwners external returns(bool)  {
    require(userControl[useAddr] == false);  
    require(balance[useAddr] >= value);

    balance[useAddr] -= value;
    totalSupply_ -= value;
    totalUsed += value;

    emit UsedSGDS(useAddr,value);
    emit Transfer(useAddr,address(0),value);

    return true;
  }

 
  function intTransfer(address _from, address _to, uint256 _value) external onlyOwners returns(bool){
    require(userControl[_from] == false);   
    require(balance[_from] >= _value);
    require(_to != address(0));
        
    balance[_from] -= _value; 
    balance[_to] += _value;
    
    emit Transfer(_from,_to,_value);
    return true;
  }

   
  
  function transferWallet(address _from,address _to) external onlyOwners{
        require(userControl[_from] == false);
        require(balance[_from] > transFee);   
        uint256  value = balance[_from];

        balance[_from] = balance[_from].sub(value);
        balance[_to] = balance[_to].add(value - transFee);  

        emit TransferWallet(_from,_to,msg.sender);
        emit Transfer(_from,_to,value - transFee);
        emit FeeTransfer(_to,transFee);
  }

 
  function setUserControl(bool _control) public {
    userControl[msg.sender] = _control;
    emit SetControlToken(msg.sender,_control);
  }

  function getUserControl(address _addr) external view returns(bool){
    return userControl[_addr];
  }
  
  function setTransFee(uint256 _fee) onlyOwners public{
    transFee = _fee;
  }
}