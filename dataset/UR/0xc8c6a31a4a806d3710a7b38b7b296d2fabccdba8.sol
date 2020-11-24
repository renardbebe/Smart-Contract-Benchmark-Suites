 

pragma solidity ^0.4.10;

 

contract elixir {
    
string public name; 
string public symbol; 
uint8 public decimals;
uint256 public totalSupply;
  
 
mapping(address => uint256) balances;

bool public balanceImportsComplete;

address exorAddress;
address devAddress;

 
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
event Transfer(address indexed from, address indexed to, uint256 value);
  
 
mapping(address => mapping (address => uint256)) allowed;
  
function elixir() {
    name = "elixir";
    symbol = "ELIX";
    decimals = 18;
    devAddress=0x85196Da9269B24bDf5FfD2624ABB387fcA05382B;
    exorAddress=0x898bF39cd67658bd63577fB00A2A3571dAecbC53;
}

function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
}

 
function transfer(address _to, uint256 _amount) returns (bool success) {
    if (balances[msg.sender] >= _amount 
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(msg.sender, _to, _amount); 
        return true;
    } else {
        return false;
    }
}

function createAmountFromEXORForAddress(uint256 amount,address addressProducing) public {
    if (msg.sender==exorAddress) {
         
        elixor EXORContract=elixor(exorAddress);
        if (EXORContract.returnAmountOfELIXAddressCanProduce(addressProducing)==amount){
             
            balances[addressProducing]+=amount;
            totalSupply+=amount;
        }
    }
}

function transferFrom(
    address _from,
    address _to,
    uint256 _amount
) returns (bool success) {
    if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;
        return true;
    } else {
        return false;
    }
}

 
function lockBalanceChanges() {
    if (tx.origin==devAddress) {  
       balanceImportsComplete=true;
   }
}

 
function importAmountForAddresses(uint256[] amounts,address[] addressesToAddTo) public {
   if (tx.origin==devAddress) {  
       if (!balanceImportsComplete)  {
           for (uint256 i=0;i<addressesToAddTo.length;i++)  {
                address addressToAddTo=addressesToAddTo[i];
                uint256 amount=amounts[i];
                balances[addressToAddTo]+=amount;
                totalSupply+=amount;
           }
       }
   }
}

 
function removeAmountForAddresses(uint256[] amounts,address[] addressesToRemoveFrom) public {
   if (tx.origin==devAddress) {  
       if (!balanceImportsComplete)  {
           for (uint256 i=0;i<addressesToRemoveFrom.length;i++)  {
                address addressToRemoveFrom=addressesToRemoveFrom[i];
                uint256 amount=amounts[i];
                balances[addressToRemoveFrom]-=amount;
                totalSupply-=amount;
           }
       }
   }
}

 
function removeFromTotalSupply(uint256 amount) public {
   if (tx.origin==devAddress) {  
       if (!balanceImportsComplete)  {
            totalSupply-=amount;
       }
   }
}


 
 
function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
}
}

contract elixor {
    function returnAmountOfELIXAddressCanProduce(address producingAddress) public returns(uint256);
}