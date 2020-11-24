 

pragma solidity >=0.4.22 <0.6.0;

contract BWSERC20
{
    string public standard = 'https: 
    string public name="Bretton Woods system";  
    string public symbol="BWS";  
    uint8 public decimals = 18;   
    uint256 public totalSupply=100000000 ether;  
    
    address st_owner;
    address st_owner1;

    uint256 public st_bws_pool; 
    uint256 public st_ready_for_listing; 
    bool st_unlock_owner=false;
    bool st_unlock_owner1=false;
    address st_unlock_to;
    address st_unlock_to1;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint32) public CredibleContract; 
     
    event Transfer(address indexed from, address indexed to, uint256 value);   
    event Burn(address indexed from, uint256 value);   
    
    
    constructor (address owner1)public
    {
        st_owner=msg.sender;
        st_owner1=owner1;
        
        st_bws_pool = 70000000 ether;
        st_ready_for_listing = 14000000 ether;
        
        balanceOf[st_owner]=8000000 ether;
        balanceOf[st_owner1]=8000000 ether;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {

       
      require(_to != address(0x0));
       
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
    
     
    function unlock_listing(address _to) public
    {
        require(_to != address(0x0),"参数中传入了空地址");
         
        if(msg.sender==st_owner)
        {
            st_unlock_owner=true;
            st_unlock_to=_to;
        }
        else if(msg.sender==st_owner1)
        {
            st_unlock_owner1=true;
            st_unlock_to1=_to;
        }
        
        if(st_unlock_owner =true && st_unlock_owner1==true && st_unlock_to !=address(0x0) && st_unlock_to==st_unlock_to1)
        {
             
            if(st_ready_for_listing==14000000 ether)
                {
                    st_ready_for_listing=0;
                    balanceOf[_to]+=14000000 ether;
                }
            
        }
    }
     
    function set_CredibleContract(address tract_address) public
    {
        require(tract_address != address(0x0),"参数中传入了空地址");
         
        if(msg.sender==st_owner)
        {
            if(CredibleContract[tract_address]==0)CredibleContract[tract_address]=2;
            else if(CredibleContract[tract_address]==3)CredibleContract[tract_address]=1;
        }
        if(msg.sender==st_owner1 )
        {
            if(CredibleContract[tract_address]==0)CredibleContract[tract_address]=3;
            else if(CredibleContract[tract_address]==2)CredibleContract[tract_address]=1;
        }
    }
    
     
    function TransferFromPool(address _to ,uint256 _value)public
    {
        require(CredibleContract[msg.sender]==1,"非法的调用");
        require(_value<=st_bws_pool,"要取出的股币数量太多");
        
        st_bws_pool-=_value;
        balanceOf[_to] +=_value;
        emit Transfer(address(this), _to, _value);
    }
}