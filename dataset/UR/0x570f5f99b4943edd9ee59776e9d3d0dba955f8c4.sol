 

pragma solidity >=0.4.22 <0.6.0;

contract BWSERC20
{
    string public standard = 'https: 
    string public name="Bretton Woods system";  
    string public symbol="BWS";  
    uint8 public decimals = 18;   
    uint256 public totalSupply=100000000 ether;  

    uint256 public st_bws_pool; 
    uint256 public st_ready_for_listing; 

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint32) public CredibleContract; 
     
    event Transfer(address indexed from, address indexed to, uint256 value);   
    event Burn(address indexed from, uint256 value);   
    
    function _transfer(address _from, address _to, uint256 _value) internal;
    
    function transfer(address _to, uint256 _value) public ;
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success) ;
    
     
    function unlock_listing(address _to) public;
     
    function set_CredibleContract(address tract_address) public;
    
     
    function TransferFromPool(address _to ,uint256 _value)public;
}

contract BWS_ICO
{
     
    BWSERC20 public st_bws_erc = BWSERC20(0x95eBEBf79Bf59b6DeE7e7709D0F67Bae81DCA09C); 
    uint160 private st_random;
    uint32 private st_rnd_index=0;
    event BackBWSNumber(address add_r,uint32 BWS,uint32 Bei);
    event BSWtoETH(uint256 eth);
    address payable st_admin;
     
    constructor()public
    {
        st_admin=msg.sender;
        st_random=uint160(msg.sender);
    }
     
    function GetRandom(uint32 num)private returns(uint32)
    {
        require(num>0);
        
        uint32 [50] memory prime=[uint32(1),2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,193,197,199,211,223,227];
        uint160 random=st_random/2+uint160(msg.sender);
        random/=prime[st_rnd_index];
        st_random=uint160(ripemd160(abi.encode(random)));
        uint32 ret=uint32(st_random % num);
        if(++st_rnd_index==50)
        {
            st_rnd_index=0;
        }
        return ret;
    }
     
    function wheel_of_fortune()public payable
    {
        require(msg.value>=0.02 ether,"每次游戏必须0.02ETH");
        uint32 rnd=GetRandom(1000); 
        uint32 multiple=0;
        if(rnd<=50)multiple=5;
        else if(rnd<=150)multiple=8;
        else if(rnd<=650)multiple=10;
        else if(rnd<=844)multiple=15;
        else if(rnd<=944)multiple=20;
        else if(rnd<=994)multiple=30;
        else if(rnd<=999)multiple=50;
        else if(rnd==1000)multiple=100;
        
        uint256 value=msg.value*10000;
        require(multiple>=5 && multiple <=100,"随机数不正常");
        value=value*multiple/10;
        
        uint256 this_bws=st_bws_erc.balanceOf(address(this));
        assert(this_bws>=value);
        
         
        st_admin.transfer(msg.value/2);
        
        st_bws_erc.transfer(msg.sender,value);
        
        emit BackBWSNumber(msg.sender,uint32(value/10000000000000000),multiple);
    }
     
    function GetETHformBWS(uint256 bws)public
    {
        require(bws>0,"bws为0");
        uint256 my_bws=st_bws_erc.balanceOf(msg.sender);
        require(bws<=my_bws,"BWS数量不足");
        address add=address(this);
        uint256 pool_eth = add.balance;
        require(pool_eth>=bws/20000,"兑币池资金不足");
        
        uint256 allowance=st_bws_erc.allowance(msg.sender,add);
        require(allowance>=bws,"本合约权限不足，请给本合约授权");
        
        st_bws_erc.transferFrom(msg.sender,add,bws);
        
        msg.sender.transfer(bws/20000);
        
        emit BSWtoETH(bws/20000);
    }
     
    function DeleteContract()public
    {
        require(msg.sender==st_admin);
        st_bws_erc.transfer(st_admin,st_bws_erc.balanceOf(address(this)));
          
        selfdestruct(st_admin);
    }
}