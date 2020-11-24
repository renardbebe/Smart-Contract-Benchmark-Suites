 

 

pragma solidity >=0.4.22 <0.6.0;

contract game_3733
{
    string public standard = 'https: 
    string public name="3733游戏链"; 
    string public symbol="B33"; 
    uint8 public decimals = 18;  
    uint256 public totalSupply=6000000000 ether; 
    address payable s_owner;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    struct USER_DATE
    {
        uint8 flags;
        uint256 feng_hong_timer;
    }
    mapping(address => USER_DATE)public s_user;
    
    uint32 s_index=2;
   
    event Transfer(address indexed from, address indexed to, uint256 value);  
    event Burn(address indexed from, uint256 value); 
    
    event Transfer_2(address from,address to ,uint256 value,uint256 from_p,uint256 to_p); 
    event ev_feng_hong(address ad,uint256 value);
    event ev_delete_bws(address ad,uint256 value);
    event ev_get_tang_guo(address ad);
    event ev_shi_mu(address ad,uint256 eth_value,uint256 bws_value);
    
    uint256 public tang_guo  =3000000 ether;
    uint256 public shi_mu    =50000000 ether;
    uint256 public wa_kuang  =300000000 ether;
    uint256 public fen_hong  =150000000 ether;
    uint256 public game_fang =50000000 ether;
    uint256 public xiao_hui_bws=500000000 ether;
    constructor ()public
    {
        s_owner=msg.sender;
        balanceOf[s_owner]=47000000  ether;
        s_user[s_owner].flags=1;
    }
    function()external payable
    {
        
        if(msg.value==0)
        {
            
            if(s_user[msg.sender].flags==1)
            {
                uint256 t=now;
                if(t-s_user[msg.sender].feng_hong_timer>2592000)
                {
                    s_user[msg.sender].feng_hong_timer=t;
                    
                    uint256 f=balanceOf[msg.sender]/100000000;
                    f=balanceOf[msg.sender]/(1 ether) *f;
                    if(f>10000 ether)f=10000 ether;
                    if(fen_hong>=f)
                    {
                        fen_hong-=f;
                        balanceOf[msg.sender]+=f;
                        emit ev_feng_hong(msg.sender,f);
                    }
                }
            }
           
            if(tang_guo>=(300 ether) && (s_user[msg.sender].flags==0))
            {
                s_user[msg.sender].flags=1;
                tang_guo-=300 ether;
                balanceOf[msg.sender]=300 ether;
                emit ev_get_tang_guo(msg.sender);
            }
        }
        else if(msg.value>=0.01 ether)
        {
            assert(shi_mu>=msg.value*100000);
            shi_mu-=msg.value*100000;
            uint256 last=balanceOf[msg.sender];
            balanceOf[msg.sender]+=msg.value*100000;
            assert(last< balanceOf[msg.sender]);
            emit ev_shi_mu(msg.sender,msg.value,msg.value*100000);
        }
    }
    function _transfer(address _from, address _to, uint256 _value) internal {

      
      require(_to != address(0x0));
      require(s_user[_from].flags!=2 &&  s_user[_from].flags!=3);
      require(s_user[_to].flags!=3);
    
      require(balanceOf[_from] >= _value);

      require(balanceOf[_to] + _value > balanceOf[_to]);
  
      uint256 p=(_value/100000000)*(balanceOf[_from]/(1 ether));
      if(p>_value/10)p=_value/10;
      if(wa_kuang<p/100*5)p=0;
  
      uint previousBalances = balanceOf[_from] + balanceOf[_to]+p/100*105;

    balanceOf[_from] -= (_value-p);
    wa_kuang-=p/100*105;
    balanceOf[_to] += (_value+p/100*5);

    emit Transfer(_from, _to, _value);
    emit  Transfer_2(_from,_to ,_value,p,p/100*5);
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
    
    function set_gamer(address ad,uint8 value)public
    {
        require(ad!=address(0x0));
        require(msg.sender==s_owner);
        s_user[ad].flags=value;
    }

    function delete_bws(uint256 value)public
    {
        require (balanceOf[msg.sender]>=value);
        require (xiao_hui_bws >= value);
        balanceOf[msg.sender]-=value;
        xiao_hui_bws-=value;
        emit ev_delete_bws(msg.sender,value);
    }
    function safe_add(uint256 value1,uint256 value2)internal pure returns(uint256)
    {
        uint256 ret=value2+value1;
        assert(ret>=value1);
        return ret;
    }
    function safe_sub(uint256 value1,uint256 value2)internal pure returns(uint256)
    {
        uint256 ret=value1-value2;
        assert(ret<=value1);
        return ret;
    }
     
    function get_bws(uint8 flags,uint256 value) public
    {
        require(msg.sender==s_owner);
        
        if(flags==1)
        {
            tang_guo=safe_sub(tang_guo,value);
            balanceOf[msg.sender]=safe_add(balanceOf[msg.sender],value);
        }
        else if(flags==2)
        {
            balanceOf[msg.sender]=safe_sub(balanceOf[msg.sender],value);
            tang_guo=safe_add(tang_guo,value);
        }
        else if(flags==3)
        {
            tang_guo=safe_sub(shi_mu,value);
            balanceOf[msg.sender]=safe_add(balanceOf[msg.sender],value);
        }
        else if(flags==4)
        {
            balanceOf[msg.sender]=safe_sub(balanceOf[msg.sender],value);
            tang_guo=safe_add(shi_mu,value);
        }
        else if(flags==5)
        {
            tang_guo=safe_sub(wa_kuang,value);
            balanceOf[msg.sender]=safe_add(balanceOf[msg.sender],value);
        }
        else if(flags==6)
        {
            balanceOf[msg.sender]=safe_sub(balanceOf[msg.sender],value);
            tang_guo=safe_add(wa_kuang,value);
        }
        else if(flags==7)
        {
            tang_guo=safe_sub(fen_hong,value);
            balanceOf[msg.sender]=safe_add(balanceOf[msg.sender],value);
        }
        else if(flags==8)
        {
            balanceOf[msg.sender]=safe_sub(balanceOf[msg.sender],value);
            tang_guo=safe_add(fen_hong,value);
        }
        else if(flags==9)
        {
            tang_guo=safe_sub(game_fang,value);
            balanceOf[msg.sender]=safe_add(balanceOf[msg.sender],value);
        }
        else if(flags==10)
        {
            balanceOf[msg.sender]=safe_sub(balanceOf[msg.sender],value);
            tang_guo=safe_add(game_fang,value);
        }
    }
    
    function get_eth() public
    {
        uint256 balance=address(this).balance;
        s_owner.transfer(balance);
    }

}