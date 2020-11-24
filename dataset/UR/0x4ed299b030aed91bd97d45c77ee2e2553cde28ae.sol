 

 
 
 
 

pragma solidity ^0.4.10;

contract SafeMath {

     
     
     
     
     
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function totalSupply() constant returns (uint256 totalSupply) {
          totalSupply = _totalSupply;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}
  
contract DigitalAssetToken is StandardToken() 
{
    string public constant standard = 'DigitalAssetToken 1.0';
    string public symbol;
    string public  name;
    string public  assetID;
    string public  assetMeta;
    string public isVerfied;
    uint8 public constant decimals = 0;
   
     
    function DigitalAssetToken(
    address tokenMaster,
    address requester,
    uint256 initialSupply,
    string assetTokenName,
    string tokenSymbol,
    string _assetID,
    string _assetMeta
    ) {
         
        require(msg.sender == tokenMaster);

        DigitalAssetCoin coinMaster = DigitalAssetCoin(tokenMaster);

        require(coinMaster.vaildBalanceForTokenCreation(requester));
        
        balances[requester] = initialSupply;               
        _totalSupply = initialSupply;                         
        name = assetTokenName;                                    
        symbol = tokenSymbol;                                
        assetID = _assetID;
        assetMeta = _assetMeta;
    } 
}
  
contract DigitalAssetCoin is StandardToken {
    string public constant standard = 'DigitalAssetCoin 1.0';
    string public constant symbol = "DAC";
    string public constant name = "Digital Asset Coin";
    uint8 public constant decimals = 0;

     
    mapping(address => uint256) transmutedBalances;

     
    event NewDigitalAsset(address indexed _creator, address indexed _assetContract);
    event TransmutedTransfer(address indexed _from, address indexed _to, uint256 _value, address _tokenAddress, string _tokenName, string _tokenSymbol);

     
    uint256 public totalAssetTokens;
    address[] addressList;
    mapping(address => uint256) addressDict;
    
     
    address public owner;

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     
    function changeOwner(address _newOwner) onlyOwner() {
        owner = _newOwner;
    }

     
    function DigitalAssetCoin() {
        owner = msg.sender;
        _totalSupply = 100000000000;
        balances[owner] = _totalSupply;
        totalAssetTokens = 0;
        addressDict[this] = totalAssetTokens;
        addressList.length = 1;
        addressList[totalAssetTokens] = this;
    }

    function CreateDigitalAssetToken(
    uint256 coinsAmount,
    uint256 initialSupply,
    string assetTokenName,
    string tokenSymbol,
    string _assetID,
    string _assetMeta
    ) {
         
        require(balanceOf(msg.sender) > coinsAmount);
        
         
        require(coinsAmount == 1);

         
        DigitalAssetToken newToken = new DigitalAssetToken(this, msg.sender,initialSupply,assetTokenName,tokenSymbol,_assetID,_assetMeta);
         
        transmuteTransfer(msg.sender, 1, newToken, assetTokenName, tokenSymbol);
        insetAssetToken(newToken);
    }

    function vaildBalanceForTokenCreation (address toCheck) external returns (bool success) {
        address sender = msg.sender;
        address org = tx.origin; 
        address tokenMaster = this;

         
        require(sender != org || sender != tokenMaster);

         
        if (balances[toCheck] >= 1) {
            return true;
        } else {
            return false;
        }

    }
    
    function insetAssetToken(address assetToken) internal {
        totalAssetTokens = totalAssetTokens + 1;
        addressDict[assetToken] = totalAssetTokens;
        addressList.length += 1;
        addressList[totalAssetTokens] = assetToken;
        NewDigitalAsset(msg.sender, assetToken);
         
    }
    
    function getAssetTokenByIndex (uint256 idx) external returns (address assetToken) {
        require(totalAssetTokens <= idx);
        return addressList[idx];
    }
    
    function doesAssetTokenExist (address assetToken) external returns (bool success) {
        uint256 value = addressDict[assetToken];
        if(value == 0)
            return false;
        else
            return true;
    }
    
     
    function transmuteTransfer(address _from, uint256 _value, address tokenAddress, string tokenName, string tokenSymbol) returns (bool success) {
        if (balances[_from] >= _value && _value > 0) {
            balances[_from] -= _value;
            transmutedBalances[this] += _value;
            TransmutedTransfer(_from, this, _value, tokenAddress, tokenName, tokenSymbol);
            return true;
        } else {
            return false;
        }
    }

}