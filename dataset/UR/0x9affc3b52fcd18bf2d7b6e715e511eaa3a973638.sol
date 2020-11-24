 

 

pragma solidity 0.5.12;   





 
 
 
 
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
        require(_newOwner != address(0), 'Invalid address');
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
 

    
 
 
 
    
contract NexxusCoin is owned {
    

     

     
    using SafeMath for uint256;
    string constant public name = "Nexxus";
    string constant public symbol = "NXR";
    uint256 constant public decimals = 8;
    uint256 public totalSupply = 375000000 * (10**decimals);    
	uint256 constant public maxSupply = 375000000 * (10**decimals);    
    bool public safeguard;   

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;


     

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
        
     
    event FrozenAccounts(address target, bool frozen);
    
     
    event Approval(address indexed from, address indexed spender, uint256 value);


     

     
    function _transfer(address _from, address _to, uint _value) internal {
        
         
        require(!safeguard, 'Safeguard is placed');
        require(!frozenAccount[_from], 'Frozen Account');                      
        require(!frozenAccount[_to], 'Frozen Account');                        
        require(_to != address(0), 'Invalid address');
         
        balanceOf[_from] = balanceOf[_from].sub(_value);     
        balanceOf[_to] = balanceOf[_to].add(_value);         
        
         
        emit Transfer(_from, _to, _value);
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
        require(!safeguard, 'Safeguard is placed');
        require(balanceOf[msg.sender] >= _value, 'Balance does not have enough tokens');
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


     
    
    constructor() public{
         
        balanceOf[owner] = totalSupply;
        
         
        emit Transfer(address(0), owner, totalSupply);
    }
    
    
     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(allowance[msg.sender][spender] > 0 ,"no amount is approved" );
        uint256 newAmount = allowance[msg.sender][spender].add(addedValue);
        approve(spender, newAmount);
        
        return true;
    }
    
    
     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(allowance[msg.sender][spender] >= subtractedValue,"subtractedValue is not correct" );
        uint256 newAmount = allowance[msg.sender][spender].sub(subtractedValue);
        approve(spender, newAmount);
        
        return true;
    }
    
    
     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success)  {
        approve(_spender, _value);
        (bool result,) = _spender.call(abi.encodeWithSignature("receiveApproval(address,uint256,address,bytes)", msg.sender, _value, address(this), _extraData));
        if(!result){
            return false;
        }
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard, 'Safeguard is placed');
         
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);   
        totalSupply = totalSupply.sub(_value);                       
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(!safeguard, 'Safeguard is placed');
         
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);  
        totalSupply = totalSupply.sub(_value);                                    
        emit  Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }
        
    
     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }
    
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
		require(totalSupply.add(mintedAmount) <= maxSupply, 'Cannot Mint more than maximum supply');
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
    }

        

     
    
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner{
         
        _transfer(address(this), owner, tokenAmount);
    }
    
    
     
    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;    
        }
    }
    

     
     
     
    
    
     
    function airdrop(address[] memory recipients,uint256[] memory tokenAmount) public  {
        uint256 totalAddresses = recipients.length;
        require(totalAddresses <= 150,"Too many recipients");
        for(uint i = 0; i < totalAddresses; i++)
        {
           
           
          transfer(recipients[i], tokenAmount[i]);
        }
    }
    
 

}