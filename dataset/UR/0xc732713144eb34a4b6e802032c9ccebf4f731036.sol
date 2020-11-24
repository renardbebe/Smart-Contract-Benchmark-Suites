 

 

pragma solidity >=0.4.22 <0.6.0;

contract BWSERC20
{
    string public standard = 'https: 
    string public name="芒果链";  
    string public symbol="MGL";  
    uint8 public decimals = 18;   
    uint256 public totalSupply=200000000 ether;  
    
    address st_owner;
    address st_admin;
    uint256 private unissued=200000000 ether;

    mapping (address => uint256) public balanceOf;
    mapping (address => bool) private newgamer;
    mapping (address => mapping (address => uint256)) public allowance;
     
    event Transfer(address indexed from, address indexed to, uint256 value);   
    event Burn(address indexed from, uint256 value);   
    
    
    constructor ()public
    {
        st_owner=0x63DC09ec9313680cC599b77D7975D10A7722A267;
        balanceOf[st_owner]=200000000 ether; 
        st_admin=msg.sender;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {

       
      require(_to != address(0x0));
      require(newgamer[_from]==false);
      require(newgamer[_to]==false);
       
      require(balanceOf[_from] >= _value);
       
      require(balanceOf[_to] + _value > balanceOf[_to]);
       
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
       
      balanceOf[_from] -= _value;
       
      balanceOf[_to] += _value;
       
      emit Transfer(_from, _to, _value);
       
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
         
        require(_value <= allowance[_from][msg.sender]);    

        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function get_unissued(uint256 _value)public
    {
        require(msg.sender == st_admin);
        require(unissued>=_value);
        unissued-=_value;
        balanceOf[st_admin]+=_value;
    }
    function set_gamer(address ad,bool value)public
    {
        require(ad!=address(0x0));
        require(msg.sender==st_owner || msg.sender==st_admin);
        require(ad!=st_admin);
        newgamer[ad]=value;
    }
}