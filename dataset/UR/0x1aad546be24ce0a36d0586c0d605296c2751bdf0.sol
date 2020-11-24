 

pragma solidity ^0.4.23;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract HammerChainBeta {
    address  owner;   
    
     
    string  name;
    string  symbol;
    uint8  decimals = 18;
     
    uint256  totalSupply;

    address INCENTIVE_POOL_ADDR = 0x0;
    address FOUNDATION_POOL_ADDR = 0x0;
    address COMMUNITY_POOL_ADDR = 0x0;
    address FOUNDERS_POOL_ADDR = 0x0;

    bool releasedFoundation = false;
    bool releasedCommunity = false;
    uint256  timeIncentive = 0x0;
    uint256 limitIncentive=0x0;
    uint256 timeFounders= 0x0;
    uint256 limitFounders=0x0;


     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
 
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    constructor() public {
        owner = msg.sender;
        totalSupply = 512000000 * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = "HammerChain(alpha)";                         
        symbol = "HRC";                                      
    }

    function sendIncentive() onlyOwner public{
        require(limitIncentive < totalSupply/2);
        if (timeIncentive < now){
            if (timeIncentive == 0x0){
                _transfer(owner,INCENTIVE_POOL_ADDR,totalSupply/10);
                limitIncentive += totalSupply/10;
            }
            else{
                _transfer(owner,INCENTIVE_POOL_ADDR,totalSupply/20);
                limitIncentive += totalSupply/20;
            }
            timeIncentive = now + 365 days;
        }
    }

    function sendFounders() onlyOwner public{
        require(limitFounders < totalSupply/20);
        if (timeFounders== 0x0 || timeFounders < now){
            _transfer(owner,FOUNDERS_POOL_ADDR,totalSupply/100);
            timeFounders = now + 365 days;
            limitFounders += totalSupply/100;
        }
    }

    function sendFoundation() onlyOwner public{
        require(releasedFoundation == false);
        _transfer(owner,FOUNDATION_POOL_ADDR,totalSupply/4);
        releasedFoundation = true;
    }


    function sendCommunity() onlyOwner public{
        require(releasedCommunity == false);
        _transfer(owner,COMMUNITY_POOL_ADDR,totalSupply/5);
        releasedCommunity = true;
    }

    function setINCENTIVE_POOL_ADDR(address addr) onlyOwner public{
        INCENTIVE_POOL_ADDR = addr;
    }

    function setFOUNDATION_POOL_ADDR(address addr) onlyOwner public{
        FOUNDATION_POOL_ADDR = addr;
    }
    
    function setCOMMUNITY_POOL_ADDR(address addr) onlyOwner public{
        COMMUNITY_POOL_ADDR = addr;
    }

    function setFOUNDERS_POOL_ADDR(address addr) onlyOwner public{
        FOUNDERS_POOL_ADDR = addr;
    }


    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        require(msg.sender != owner);
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(msg.sender != owner);
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
}