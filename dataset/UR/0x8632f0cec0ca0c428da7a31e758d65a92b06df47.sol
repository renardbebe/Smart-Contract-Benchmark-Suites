 

pragma solidity 0.5.11;   




 
 
 
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}


 
 
 
    
contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
 

    
 
 
 
    
contract Banxcoin is owned {
    

     

     
    using SafeMath for uint256;
    string constant public name = "Banx coin";
    string constant public symbol = "BXN";
    uint256 constant public decimals = 18;
    uint256 public totalSupply;
    
    address public burnAddress;      
    bool public safeguard;       

     
    uint256 public totalVestedTokens = 500000000 * (10**decimals);       
    uint256 public monthlyVestingRelease = totalVestedTokens / 100;      
    uint256 public vestedTokensWithdrawn;                                
    uint256 public deploymentTimestamp;
    
    
    
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => bool) public transferAccounts;
    mapping (address => bool) public burnAccounts;
    mapping (address => bool) public minterAccounts;
    mapping (address => bool) public creatorAccounts;



     

     
    modifier onlyTransferOperator {
        require(transferAccounts[msg.sender]);
        _;
    }

     
    modifier onlyBurnOperator {
        require(burnAccounts[msg.sender]);
        _;
    }

     
    modifier onlyMintOperator {
        require(minterAccounts[msg.sender]);
        _;
    }

     
    modifier onlyOwnerOrCreator {
        require(creatorAccounts[msg.sender] || msg.sender == owner);
        _;
    }


     

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, address indexed to, uint256 value);
        
     
    event Mint(address indexed to, uint256 value);
        
     
    event FrozenAccounts(address target, bool frozen);
    
     
    event Approval(address indexed from, address indexed spender, uint256 value);

     
    event AddOperator(address indexed operator, string  role);
    
     
    event RemoveOperator(address indexed operator, string  role);
    
     
    event UpdateBurnAddress(address indexed oldAddress, address indexed newAddress, uint256  timestamp);
    
     
    event WithdrawVestedTokens(address userAddress, uint256 numberOfTokens);

     

     
    function _transfer(address _from, address _to, uint _value) internal {
        
         
        require(!safeguard);
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        
		if(_to == burnAddress)
		{
			burn(_from, _value);
		}
		else
		{
             
            balanceOf[_from] = balanceOf[_from].sub(_value);     
            balanceOf[_to] = balanceOf[_to].add(_value);         
            
             
            emit Transfer(_from, _to, _value);
		}
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        
         
        _transfer(msg.sender, _to, _value);
        
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


     
    
    constructor() public{
        
         
        deploymentTimestamp = now;
        
        burnAddress = address(this);

    }
    
     
    function () external payable {}

     
    function burn(address _from, uint256 _value) internal returns (bool success) {

         
        balanceOf[_from] = balanceOf[_from].sub(_value);             
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(_from, burnAddress, _value);
        emit Transfer(_from, burnAddress, _value);
        return true;
    }


     
    function burnFrom(address _from, uint256 _value) onlyBurnOperator public returns (bool success) {
        
        require(!safeguard);
        
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);  
        
        burn(_from, _value);
        
        return true;
    }


     
    function freezeAccount(address target, bool freeze) onlyOwner public {
            frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }
    
     
    function _mintToken(address target, uint256 mintedAmount) internal {
        
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Mint(target, mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
    }
    
    function mintToken(address target, uint256 mintedAmount) onlyMintOperator public {
        _mintToken(target, mintedAmount);
    }



     
    
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner{
         
        _transfer(address(this), owner, tokenAmount);
    }
    
     
    function manualWithdrawEther()onlyOwner public{
        address(owner).transfer(address(this).balance);
    }
    
     
    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }

     
    function updateBurnAddress(address _burnAddress) onlyOwner public {
        address oldAddress = burnAddress;
        burnAddress = _burnAddress;
        emit UpdateBurnAddress(oldAddress, _burnAddress, now);
    }
    

    
    
     
    

    function addBurnAccount(address operator) onlyOwnerOrCreator public returns(bool) {
        burnAccounts[operator] = true;
        emit  AddOperator(operator, 'Burn');
        return true;
    }
    
    function removeBurnAccount(address operator) onlyOwnerOrCreator public returns(bool) {
        burnAccounts[operator] = false;
        emit  RemoveOperator(operator, 'Burn');
        return true;
    }

    function addMinterAccount(address operator) onlyOwnerOrCreator public returns(bool) {
        minterAccounts[operator] = true;
        emit  AddOperator(operator, 'Minter');
        return true;
    }
    
    function removeMinterAccount(address operator) onlyOwnerOrCreator public returns(bool) {
        minterAccounts[operator] = false;
        emit  RemoveOperator(operator, 'Minter');
        return true;
    }
    
    function addCreatorAccount(address operator) onlyOwnerOrCreator public returns(bool) {
        creatorAccounts[operator] = true;
        emit  AddOperator(operator, 'Creator');
        return true;
    }
    
    function removeCreatorAccount(address operator) onlyOwnerOrCreator public returns(bool) {
        creatorAccounts[operator] = false;
        emit  RemoveOperator(operator, 'Creator');
        return true;
    }
    
    
     

     
    function availableTokensFromVesting() public view returns(uint256) {
        
        uint256 currentTimeStamp = now;
        uint256 vestingStartTimestamp = deploymentTimestamp + 5184000;   
        
        if(currentTimeStamp < vestingStartTimestamp || vestedTokensWithdrawn >= totalVestedTokens)
        {
            return 0;
        }
        else
        {
            
            uint256 timestampDiff = currentTimeStamp - vestingStartTimestamp;
            uint256 numMonths = 1 + (timestampDiff / 2592000);         
            uint256 tokensAllTime = monthlyVestingRelease * numMonths;
            
            return tokensAllTime - vestedTokensWithdrawn;
            
        }

   }
   
    
   function withdrawVestingTokens() onlyOwner public returns (bool) {
       
       uint256 tokensToWithdraw = availableTokensFromVesting();
       
       if(tokensToWithdraw > 0){
           
           _mintToken(msg.sender, tokensToWithdraw);
           vestedTokensWithdrawn += tokensToWithdraw;

           emit WithdrawVestedTokens(msg.sender, tokensToWithdraw);
           return true;
       }
   }
   
   

}