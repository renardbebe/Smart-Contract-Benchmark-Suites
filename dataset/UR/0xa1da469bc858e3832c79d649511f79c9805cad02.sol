 

pragma solidity 0.5.11;    




 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


 
 
 

interface InterfaceDividend {
    function withdrawDividendsEverything() external returns(bool);
}




 
 
 

contract ownerShip     
{
     
    address payable public owner;

    address payable public newOwner;

    bool public safeGuard ;  
    
     
    mapping (address => bool) public frozenAccount;

     
    event OwnershipTransferredEv(uint256 timeOfEv, address payable indexed previousOwner, address payable indexed newOwner);


     
    constructor() public 
    {
         
        owner = msg.sender;
    }

     
    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address payable _newOwner) public onlyOwner 
    {
        newOwner = _newOwner;
    }


     
    function acceptOwnership() public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(now, owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }


     
    function changesafeGuardStatus() onlyOwner public
    {
        if (safeGuard == false)
        {
            safeGuard = true;
        }
        else
        {
            safeGuard = false;    
        }
    }

     
     
     
    event FrozenAccounts(uint256 timeOfEv, address target, bool freeze);
    function freezeAccount(address target, bool freeze) onlyOwner public 
    {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(now, target, freeze);
    }



}



 
 
 

contract HRX is ownerShip {
  
    using SafeMath for uint256;       
    string constant public name="HYPERETH";
    string constant public symbol="HRX";
    uint256 constant public decimals=18;
    uint256 public totalSupply = 25000000 * ( 10 ** decimals);
    uint256 public minTotalSupply = 1000000 * ( 10 ** decimals);
    uint256 public _burnPercent = 6;   
    uint256 public frozenTokenGlobal;
    address public dividendContractAdderess;


     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public usersTokenFrozen;


  
    
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed approvedBy, address indexed spender, uint256 value);
    
     
    event TokenFrozen(address indexed user, uint256 indexed tokenAmount);
     
    event TokenUnFrozen(address indexed user, uint256 indexed tokenAmount);

  
     
    constructor() public
    {
         
        balanceOf[owner] = totalSupply;
         
        emit Transfer(address(0), owner, totalSupply);

    }
    
     
    function () payable external {}
    
     

     
    function _transfer(address _from, address _to, uint _value) internal {
        
         
        require(!safeGuard);
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        
         
        balanceOf[_from] = balanceOf[_from].sub(_value);     
        balanceOf[_to] = balanceOf[_to].add(_value);         
        
         
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        uint256 tokensToBurn = calculatePercentage(_value,_burnPercent);

         
        _transfer(msg.sender, _to, _value);
        
         
        _burn(_to, tokensToBurn);
        
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        uint256 tokensToBurn = calculatePercentage(_value,_burnPercent);
        
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        
         
        _burn(_to, tokensToBurn);
        
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        address user = msg.sender;   

        require(!safeGuard, 'safeGuard is on');
        require(!frozenAccount[user]);                      
        require(!frozenAccount[_spender]);                        
        require(_value <= balanceOf[user], 'Not enough balance');
        
        allowance[user][_spender] = _value;
        emit Approval(user, _spender, _value);
        return true;
    }
    
    
     
    
     
    function freezeTokens(uint256 _value) public returns(bool){

        address callingUser = msg.sender;
        address contractAddress = address(this);

         
         
        require(InterfaceDividend(dividendContractAdderess).withdrawDividendsEverything(), 'Outstanding div withdraw failed');
        

         
         
         
        _transfer(callingUser, contractAddress, _value);


         
        frozenTokenGlobal += _value;
        usersTokenFrozen[callingUser] += _value;


         
        emit TokenFrozen(callingUser, _value);
        
        
        return true;
    }

    function unfreezeTokens() public returns(bool){

        address callingUser = msg.sender;

         
         
        require(InterfaceDividend(dividendContractAdderess).withdrawDividendsEverything(), 'Outstanding div withdraw failed');
        
 
        uint256 _value = usersTokenFrozen[callingUser];

        require(_value > 0 , 'Insufficient Frozen Tokens');
        
         
        usersTokenFrozen[callingUser] = 0; 
        frozenTokenGlobal -= _value;
        
         
        _transfer(address(this), callingUser, _value);

         
        emit TokenUnFrozen(callingUser, _value);

        return true;

    }

    
    

     
    
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    
        uint256 newAmount = allowance[msg.sender][spender].add(addedValue);
        approve(spender, newAmount);
        
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    
        uint256 newAmount = allowance[msg.sender][spender].sub(subtractedValue);
        approve(spender, newAmount);
        
        return true;
    }


     
    function calculatePercentage(uint256 PercentOf, uint256 percentTo ) internal pure returns (uint256) 
    {
        uint256 factor = 10000;
        require(percentTo <= factor);
        uint256 c = PercentOf.mul(percentTo).div(factor);
        return c;
    }

    
    function setBurningRate(uint burnPercent) onlyOwner public returns(bool success)
    {
        _burnPercent = burnPercent;
        return true;
    }
    
    function updateMinimumTotalSupply(uint minimumTotalSupplyWEI) onlyOwner public returns(bool success)
    {
        minTotalSupply = minimumTotalSupplyWEI;
        return true;
    }
    
    
    
    function _burn(address account, uint256 amount) internal returns(bool) {
    
        if(totalSupply > minTotalSupply)
        {
          totalSupply = totalSupply.sub(amount);
          balanceOf[account] = balanceOf[account].sub(amount);
          emit Transfer(account, address(0), amount);
          return true;
        }
         
    }

    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner returns(string memory){
         
        _transfer(address(this), owner, tokenAmount);
        return "Tokens withdrawn to owner wallet";
    }


    function manualWithdrawEther(uint256 amount) public onlyOwner returns(string memory){
        owner.transfer(amount);
        return "Ether withdrawn to owner wallet";
    }

    function updateDividendContractAddress(address dividendContract) public onlyOwner returns(string memory){
        dividendContractAdderess = dividendContract;
        return "dividend conract address updated successfully";
    }

     
    function airDrop(address[] memory recipients,uint[] memory tokenAmount) public onlyOwner returns (bool) {
        uint reciversLength  = recipients.length;
        require(reciversLength <= 150);
        for(uint i = 0; i < reciversLength; i++)
        {
            if (gasleft() < 100000)
            {
                break;
            }
               
              _transfer(owner, recipients[i], tokenAmount[i]);
        }
        return true;
    }
        
         


}