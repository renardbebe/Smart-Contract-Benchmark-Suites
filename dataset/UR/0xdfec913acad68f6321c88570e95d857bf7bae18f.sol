 

pragma solidity >=0.4.22 <0.6.0;



contract EquityChain 
{
    string public standard = 'https: 
    string public name="去中心化权益链通证系统（Equity Chain System）";  
    string public symbol="ECS";  
    uint8 public decimals = 18;   
    uint256 public totalSupply=0;  
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);   
    event Burn(address indexed from, uint256 value);   

    address Old_EquityChain=address(0x0);
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
    modifier onlyPople(){
         address addr = msg.sender;
        uint codeLength;
        assembly {codeLength := extcodesize(addr)} 
        require(codeLength == 0, "sorry humans only"); 
        require(tx.origin == msg.sender, "sorry, human only"); 
        _;
    }
    modifier onlyUnLock(){
        require(msg.sender==owner || msg.sender==Longteng1 || info.is_over_finance==1);
        _;
    }
     
    function _transfer(address _from, address _to, uint256 _value) internal{

       
      require(_to != address(0x0));
       
      require(balanceOf[_from] >= _value);
       
      require(balanceOf[_to] + _value > balanceOf[_to]);
       
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
       
      balanceOf[_from] -= _value;
       
      balanceOf[_to] += _value;
       
      emit Transfer(_from, _to, _value);
       
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

       
      add_price(_value);
       
      if(st_user[_to].code==0)
      {
          register(_to,st_user[_from].code);
      }
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
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
     
    function Encryption(uint32 num) internal pure returns(uint32 com_num) {
      require(num>0 && num<=1073741823,"ID最大不能超过1073741823");
       uint32 ret=num;
        
       uint32 xor=(num<<24)>>24;
       
       xor=(xor<<24)+(xor<<16)+(xor<<8);
       
       xor=(xor<<2)>>2;
       ret=ret ^ xor;
       ret=ret | 1073741824;
        return (ret);
   }
    
    function safe_mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
 
    function safe_div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
 
    function safe_sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
 
    function safe_add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
     
    function get_scale(uint32 i)internal pure returns(uint32 )    {
        if(i==0)
            return 10;
        else if(i==1)
            return 5;
        else if(i==2)
            return 2;
        else
            return 1;
    }

      
    function register(address addr,uint32 be_code)internal{
        assert(st_by_code[be_code] !=address(0x0) || be_code ==131537862);
        info.pople_count++; 
        uint32 code=Encryption(info.pople_count);
        st_user[addr].code=code;
        st_user[addr].be_code=be_code;
        st_by_code[code]=addr;
    }
     
    function get_IPC(address ad)internal returns(bool)
    {
        uint256 ivt=(now-st_user[ad].time_of_invest)*IPC; 
        ivt=safe_mul(ivt,st_user[ad].ecs_lock)/(1 ether); 
        
        if(info.ecs_Interest>=ivt)
        {
            info.ecs_Interest-=ivt; 
             
            totalSupply=safe_add(totalSupply,ivt);
            balanceOf[ad]=safe_add(balanceOf[ad],ivt);
            st_user[ad].ecs_from_interest=safe_add(st_user[ad].ecs_from_interest,ivt); 
            st_user[ad].time_of_invest=now; 
            return true;
        }
        return false;
    }
     
    function add_price(uint256 ecs)internal
    {
        info.ecs_trading_volume=safe_add(info.ecs_trading_volume,ecs);
        if(info.ecs_trading_volume>=500000 ether) 
        {
            info.price=info.price*1005/1000;
            info.ecs_trading_volume=0;
        }
    }
     
    struct USER
    {
        uint32 code; 
        uint32 be_code; 
        uint256 eth_invest; 
        uint256 time_of_invest; 
        uint256 ecs_lock; 
        uint256 ecs_from_recommend; 
        uint256 ecs_from_interest; 
        uint256 eth; 
        uint32 OriginalStock; 
        uint8 staus; 
    }
    
    struct SYSTEM_INFO
    {
        uint256 start_time; 
        uint256 eth_totale_invest; 
        uint256 price; 
        uint256 ecs_pool; 
        uint256 ecs_invite; 
        uint256 ecs_Interest; 
        uint256 eth_exchange_pool; 
        uint256 ecs_trading_volume; 
        uint256 eth_financing_volume; 
        uint8 is_over_finance; 
        uint32 pople_count; 
    }
    address private owner;
    address private Longteng1;
    address private Longteng2;
    
    mapping(address => USER)public st_user; 
    mapping(uint32 =>address) public st_by_code; 
    SYSTEM_INFO public info;
    uint256 constant IPC=5000000000; 
     
    constructor ()public
    {
        
        owner=msg.sender;
        Longteng1=0x7d0E7BaEBb4010c839F3E0f36373e7941792AdEa;
        Longteng2=0xD67844Ad1Ca9666cFaAf723Dfb9208872326Dbf7;
        
        info.start_time=now;
        info.ecs_pool    =850000000 ether; 
        info.ecs_invite  =50000000 ether; 
        info.ecs_Interest=100000000 ether; 
        info.price=0.0001 ether;
        _Investment(owner,131537862,5000 ether);
        _Investment(Longteng1,1090584833,5000 ether);
        _Investment(Longteng2,1107427842,10000 ether);
    }
     
    function Investment(uint32 be_code)public payable onlyPople
    {
        require(info.is_over_finance==0,"融资已完成");
        require(st_by_code[be_code]!=address(0x0),'推荐码不合法');
        require(msg.value>0,'投资金额必须大于0');
        uint256 ecs=_Investment(msg.sender,be_code,msg.value);
         
        info.eth_totale_invest=safe_add(info.eth_totale_invest,msg.value);
        st_user[msg.sender].OriginalStock=uint32(st_user[msg.sender].eth_invest/(1 ether));
        totalSupply=safe_add(totalSupply,ecs); 
        if(info.ecs_pool<=1000 ether) 
        {
            info.is_over_finance=1;
        }
         
        if(info.eth_financing_volume>=500 ether)
        {
            info.price=info.price*1005/1000;
            info.eth_financing_volume=0;
        }
         
        uint32 scale;
        address ad;
        uint256 lock_ecs;
        uint256 total=totalSupply;
        uint256 ecs_invite=info.ecs_invite;
        USER storage user=st_user[msg.sender];
        for(uint32 i=0;user.be_code!=131537862;i++)
        {
            ad=st_by_code[user.be_code];
            user=st_user[ad];
            lock_ecs=user.ecs_lock*10; 
            lock_ecs=lock_ecs>ecs?ecs:lock_ecs;
            scale=get_scale(i);
            lock_ecs=lock_ecs*scale/100; 
            ecs_invite=ecs_invite>=lock_ecs?ecs_invite-lock_ecs:0;
            user.ecs_from_recommend=safe_add(user.ecs_from_recommend,lock_ecs);
            balanceOf[ad]=safe_add(balanceOf[ad],lock_ecs);
             
            total=safe_add(total,lock_ecs);
        }
        totalSupply=total;
        info.ecs_invite=ecs_invite;
         
        ecs=msg.value/1000;
         
        info.eth_exchange_pool=safe_add(info.eth_exchange_pool,ecs*100);
         
        st_user[owner].eth=safe_add(st_user[owner].eth,ecs*225);
         
        st_user[Longteng1].eth=safe_add(st_user[Longteng1].eth,ecs*225);
         
        st_user[Longteng2].eth=safe_add(st_user[Longteng2].eth,ecs*450);
    }
    
    function _Investment(address ad,uint32 be_code,uint256 value)internal returns(uint256)
    {
        if(st_user[ad].code==0) 
        {
            register(ad,be_code);
        }
         
        if(st_user[ad].time_of_invest>0)
        {
            get_IPC(ad);
        }
        
        st_user[ad].eth_invest=safe_add(st_user[ad].eth_invest,value); 
        st_user[ad].time_of_invest=now; 
         
        uint256 ecs=value/info.price*(1 ether);
        info.ecs_pool=safe_sub(info.ecs_pool,ecs); 
        st_user[ad].ecs_lock=safe_add(st_user[ad].ecs_lock,ecs);
        return ecs;
    }
     
    function un_lock()public onlyPople
    {
        uint256 t=now;
        require(t<1886955247 && t>1571595247,'时间不正确');
        if(t-info.start_time>=7776000)
            info.is_over_finance=1;
    }
     
    function eth_to_out(uint256 eth)public onlyPople
    {
        require(eth<=address(this).balance,'系统eth不足');
        USER storage user=st_user[msg.sender];
        require(eth<=user.eth,'你的eth不足');
        user.eth=safe_sub(user.eth,eth);
        msg.sender.transfer(eth);
    }
     
    function ecs_to_out(uint256 ecs)public onlyPople onlyUnLock
    {
        require(info.is_over_finance==1 || msg.sender==owner || msg.sender==Longteng1,'');
        USER storage user=st_user[msg.sender];
        require(user.ecs_lock>=ecs,'你的ecs不足');
         
        get_IPC(msg.sender);
        totalSupply=safe_add(totalSupply,ecs); 
        user.ecs_lock=safe_sub(user.ecs_lock,ecs);
        balanceOf[msg.sender]=safe_add(balanceOf[msg.sender],ecs);
    }
     
    function ecs_to_in(uint256 ecs)public onlyPople onlyUnLock
    {
         USER storage user=st_user[msg.sender];
         require(balanceOf[msg.sender]>=ecs,'你的未锁定ecs不足');
          
         get_IPC(msg.sender);
         totalSupply=safe_sub(totalSupply,ecs); 
         balanceOf[msg.sender]=safe_sub(balanceOf[msg.sender],ecs);
         user.ecs_lock=safe_add(user.ecs_lock,ecs);
    }
     
    function ecs_to_eth(uint256 ecs)public onlyPople
    {
        USER storage user=st_user[msg.sender];
        require(balanceOf[msg.sender]>=ecs,'你的已解锁ecs不足');
        uint256 eth=safe_mul(ecs/1000000000 , info.price/1000000000);
        require(info.eth_exchange_pool>=eth,'兑换资金池资金不足');
        add_price(ecs); 
        totalSupply=safe_sub(totalSupply,ecs); 
        balanceOf[msg.sender]-=ecs;
        info.eth_exchange_pool-=eth;
        user.eth+=eth;
    }
     
    function Abonus()public payable 
    {
        require(msg.value>0);
        info.eth_exchange_pool=safe_add(info.eth_exchange_pool,msg.value);
    }
     
    function get_Interest()public
    {
        get_IPC(msg.sender);
    }
     
     
    function updata_old(address ad,uint32 min,uint32 max)public onlyOwner 
    {
        EquityChain ec=EquityChain(ad);
        if(min==0) 
        {
            ec.updata_new(
                0,
                info.start_time, 
                info.eth_totale_invest, 
                info.price, 
                info.ecs_pool, 
                info.ecs_invite, 
                info.ecs_Interest, 
                info.eth_exchange_pool, 
                info.ecs_trading_volume, 
                info.eth_financing_volume, 
                info.is_over_finance, 
                info.pople_count, 
                totalSupply
            );
            min=1;
        }
        uint32 code;
        address ads;
        for(uint32 i=min;i<max;i++)
        {
            code=Encryption(i);
            ads=st_by_code[code];
            ec.updata_new(
                i,
                st_user[ads].code, 
                st_user[ads].be_code, 
                st_user[ads].eth_invest, 
                st_user[ads].time_of_invest, 
                st_user[ads].ecs_lock, 
                st_user[ads].ecs_from_recommend, 
                st_user[ads].ecs_from_interest, 
                st_user[ads].eth, 
                st_user[ads].OriginalStock, 
                balanceOf[ads],
                uint256(ads),
                0
             );
        }
        if(max>=info.pople_count)
        {
            selfdestruct(address(uint160(ad)));
        }
    }
     
    function updata_new(
        uint32 flags,
        uint256 p1,
        uint256 p2,
        uint256 p3,
        uint256 p4,
        uint256 p5,
        uint256 p6,
        uint256 p7,
        uint256 p8,
        uint256 p9,
        uint256 p10,
        uint256 p11,
        uint256 p12
        )public
    {
        require(msg.sender==Old_EquityChain);
        require(tx.origin==owner);
        address ads;
        if(flags==0)
        {
            info.start_time=p1; 
            info.eth_totale_invest=p2; 
            info.price=p3; 
            info.ecs_pool=p4; 
            info.ecs_invite=p5; 
            info.ecs_Interest=p6; 
            info.eth_exchange_pool=p7; 
            info.ecs_trading_volume=p8; 
            info.eth_financing_volume=p9; 
            info.is_over_finance=uint8(p10); 
            info.pople_count=uint32(p11); 
            totalSupply=p12;
        }
        else
        {
            ads=address(p11);
            st_by_code[uint32(p1)]=ads;
            st_user[ads].code=uint32(p1); 
            st_user[ads].be_code=uint32(p2); 
            st_user[ads].eth_invest=p3; 
            st_user[ads].time_of_invest=p4; 
            st_user[ads].ecs_lock=p5; 
            st_user[ads].ecs_from_recommend=p6; 
            st_user[ads].ecs_from_interest=p7; 
            st_user[ads].eth=p8; 
            st_user[ads].OriginalStock=uint32(p9); 
            balanceOf[ads]=p10;
        }
    }
}