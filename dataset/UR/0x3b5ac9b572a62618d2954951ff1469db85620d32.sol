 

pragma solidity ^0.4.4;

 
interface IERC20StandardToken{
     
    function totalSupply() external constant returns (uint256 supply);
   
     
    function transfer(address _to, uint256 _value) external returns (bool success);
    
     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

     
    function balanceOf(address _owner) external constant returns (uint256 balance);

     
    function approve(address _spender, uint256 _value) external returns (bool success);

     
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20StandardToken is IERC20StandardToken{
    uint256 public totalSupply;
    
    function totalSupply() external constant returns (uint256 supply){
        return totalSupply;
    }
   
     
    function transfer(address _to, uint256 _value) external returns (bool success) {
         
         
         
        
         
        if (_value > 0 && balances[msg.sender] >= _value) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract TKDToken is ERC20StandardToken {
    uint256 private constant DECIMALS_AMOUNT = 1000000000000000000;
    
     
    uint256 private constant TOTAL_SUPPLY_AMOUNT = 7500000 * DECIMALS_AMOUNT;
    
     
    uint256 private constant TOTAL_ICO_AMOUNT = 5500000 * DECIMALS_AMOUNT;
    
     
    uint256 private constant TOTAL_MARKETING_AMOUNT = 2000000 * DECIMALS_AMOUNT;
 
     
    string public name = "TKDToken";                   
    string public symbol ="TKD";
 
    uint8 public decimals =  18;
    address public fundsWallet;
    address public icoTokenAddress = 0x6ed1d3CF924E19C14EEFE5ea93b5a3b8E9b746bE;
    address public marketingTokenAddress = 0xc5DE4874bA806611b66511d8eC66Ba99398B194f;
  
     
   
     
     
    function TKDToken() public payable{
         
        balances[msg.sender] = TOTAL_SUPPLY_AMOUNT;
        totalSupply = TOTAL_SUPPLY_AMOUNT;
        fundsWallet = msg.sender;
    }
    
    function() public payable{
        uint256 ethReceiveAmount = msg.value;
        require(ethReceiveAmount > 0);
        
        address tokenReceiveAddress = msg.sender;
        
         
        require(tokenReceiveAddress == icoTokenAddress || tokenReceiveAddress == marketingTokenAddress);
        
         
        require(balances[tokenReceiveAddress] == 0);
        
        uint256 tokenSendAmount = 0;
        if(tokenReceiveAddress == icoTokenAddress){
            tokenSendAmount = TOTAL_ICO_AMOUNT;    
        }else{
            tokenSendAmount = TOTAL_MARKETING_AMOUNT;
        }
        
        require(tokenSendAmount > 0);
         
        require(balances[fundsWallet] >= tokenSendAmount);
        
         
        balances[fundsWallet] -= tokenSendAmount;
        balances[tokenReceiveAddress] += tokenSendAmount;
        
         
        emit Transfer(fundsWallet, tokenReceiveAddress, tokenSendAmount); 
        
         
        fundsWallet.transfer(msg.value);     
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) private returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { assert(false); }
        return true;
    }
}