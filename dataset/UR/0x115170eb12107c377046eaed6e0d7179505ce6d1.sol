 

pragma solidity ^0.4.21;

 

  
 
contract Manager
{
    address public contractManager;  
    
    bool public paused = false;  
	
	event NewContractManager(address newManagerAddress);  

     
    function Manager() public
	{
        contractManager = msg.sender;  
    }

	 
    modifier onlyManager()
	{
        require(msg.sender == contractManager); 
        _;
    }
    
	 
    function newManager(address newManagerAddress) public onlyManager 
	{
		require(newManagerAddress != 0);
		
        contractManager = newManagerAddress;
		
		emit NewContractManager(newManagerAddress);

    }
    
     
    event Pause();

     
    event Unpause();

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    function pause() public onlyManager whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyManager {
        require(paused);

        paused = false;
        emit Unpause();
    }


}

 
contract ERC20 is Manager
{

    mapping(address => uint256) public balanceOf;  
    
    string public name; 
	
    string public symbol; 
	
    uint256 public decimal;  
	
    uint256 public totalSupply; 
    
    mapping(address => mapping(address => uint256)) public allowance; 
    
    event Transfer(address indexed from, address indexed to, uint256 value);  
	
    event Approval(address indexed owner, address indexed spender, uint256 value); 
    
     
    function ERC20(uint256 initialSupply, string _name, string _symbol, uint256 _decimal)  public
	{
		require(initialSupply >= 0); 

		require(_decimal >= 0); 
		
        balanceOf[msg.sender] = initialSupply; 
		
        name = _name;  
		
        symbol = _symbol; 
		
        decimal = _decimal; 
		
        totalSupply = initialSupply;  
    }
    
     
    function transfer(address _to, uint256 _value)public whenNotPaused returns (bool success)
	{
		require(_value > 0); 
		
		require(balanceOf[msg.sender] >= _value); 
		
		require(balanceOf[_to] + _value >= balanceOf[_to]); 

        balanceOf[msg.sender] -= _value; 
		
        balanceOf[_to] += _value; 
		
        emit Transfer(msg.sender, _to, _value); 

        return true;
    }
    
     
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) 
	{
		require(_value > 0);  
		
		allowance[msg.sender][_spender] = _value; 

        emit Approval(msg.sender, _spender, _value); 
		
        return true;
    }
    
         
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) 
	{
      return allowance[_owner][_spender];
    }

	 
    function transferFrom(address _from, address _to, uint256 _value)public whenNotPaused returns (bool success)
	{
		require(_value > 0);  
		
        require(balanceOf[_from] >= _value); 
		
        require(balanceOf[_to] + _value >= balanceOf[_to]); 
        
        require(_value <= allowance[_from][msg.sender]);  

        balanceOf[_from] -= _value; 
		
        balanceOf[_to] += _value; 
        
        allowance[_from][msg.sender] -= _value;  

        emit Transfer(_from, _to, _value); 

        return true;
    }
    
     
    function balanceOf(address _owner)public constant returns (uint256 balance) 
	{
        return balanceOf[_owner];
    }
}

 
contract WIMT is Manager, ERC20
{
     
     
    function WIMT(uint256 _totalSupply, string _name, string _symbol, uint8 _decimal ) public  ERC20(_totalSupply, _name, _symbol, _decimal)
	{

        contractManager = msg.sender;

        balanceOf[contractManager] = _totalSupply;
		
        totalSupply = _totalSupply;
		
		decimal = _decimal;

    }
    
     
    function mint(address target, uint256 mintedAmount)public onlyManager whenNotPaused
	{
		require(target != 0); 
		
		require(mintedAmount > 0); 
		
	    require(balanceOf[target] + mintedAmount >= balanceOf[target]); 
        
        require(totalSupply + mintedAmount >= totalSupply); 
        
        balanceOf[target] += mintedAmount; 
		
        totalSupply += mintedAmount; 
		
        emit Transfer(0, this, mintedAmount); 
		
        emit Transfer(this, target, mintedAmount); 
    }
    
	 
	function burn(uint256 mintedAmount) public onlyManager whenNotPaused
	{
		
		require(mintedAmount > 0); 
		
		require(totalSupply - mintedAmount <= totalSupply); 
        
	    require(balanceOf[msg.sender] - mintedAmount <= balanceOf[msg.sender]); 

        balanceOf[msg.sender] -= mintedAmount; 
		
        totalSupply -= mintedAmount; 
		
        emit Transfer(0, msg.sender, mintedAmount); 
		
        

    }

}