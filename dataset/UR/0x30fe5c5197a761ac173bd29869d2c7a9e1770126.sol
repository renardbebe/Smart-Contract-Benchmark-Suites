 

pragma solidity ^0.5.10;


contract InstaLottos
{
    address payable private manager;
    
    uint private betamount;
    
    uint private playercount;
    
    uint private lowerbound;
    
    uint private upperbound;
    
    bool private contractactive;
    
    bool private contractpause;
    
    event Playlottery(uint cbalance, uint rndm,uint pcount);
    
    constructor() public
    {

        manager = msg.sender;
        
        contractactive = true;
        
        contractpause = false;
        
        betamount = 0.005 ether;
        
        playercount = 0;
        
        lowerbound = 1;
    
        upperbound = 100;
    }
    
    modifier onlyManager()
    {
        require(msg.sender == manager);
        _;
    }
    
   
    function getcontractactive() public view returns (bool)
    {
        return contractactive;
    }
    
     function getcontractpause() public view returns (bool)
    {
        return contractpause;
    }
    
    function getbetamount() public view returns (uint)
    {
        return betamount;
    }
  
    
    function getplayercount() public view returns (uint)
    {
        return playercount;
    }
    
    function getupperbound() public view returns(uint)
    {
        return upperbound;
    }
    
    function getmanager() public view returns(address)
    {
        return manager;
    }
    
    function getcontractbalance() public view returns(uint)
    {
        return address(this).balance;
    }
    
    function setbetamount(uint btamt) public onlyManager
    {
        betamount = btamt;
    }
    
    function setupperbound(uint upbound) public onlyManager
    {
        upperbound = upbound;
    }
    

    function setcontractpause(bool pas) public onlyManager
    {
        if (pas == false)
        {
            contractactive = true;
        }
        contractpause = pas;
    }
    
    
    function setmanager(address payable newmngr) public onlyManager
    {
        manager = newmngr;
    }
    
    
    function playlottery(uint playnum) public payable
    {
        require(contractactive==true);
        require(playnum >=lowerbound && playnum <=upperbound);
        require(msg.value == betamount);
        
        playercount++;
        
        uint rnd = random(msg.sender,playnum);
        
        if (playnum == rnd)
        {
            settlewin(msg.sender);
            emit Playlottery(getcontractbalance(),rnd,playercount);
            
            if (contractpause == true)
            {
                contractactive = false;
            }
            
            return;
        }
        
        emit Playlottery(getcontractbalance(),rnd,playercount);
        
        return;
        
    }
    
    function settlewin(address payable msgsender) private
    {
        address payable winner = msgsender;
        
        uint cb = address(this).balance;

            if (cb <= (betamount * 2))
            {
                    winner.transfer(cb);
            }
            else if (cb <=(betamount*3))
            {
            	winner.transfer((betamount*2));
            }
            else
            {
                    uint cbnow = cb - betamount;
                    uint cb90 = cbnow * 90/100;
                    uint cb10 = cbnow - cb90;
                    manager.transfer(cb10);
                    winner.transfer(cb90);
            }
            
            playercount = 0;
    }
    
    function random(address msgsender,uint numplayed) private view returns (uint)
    {
        uint tmp = uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp,block.number,playercount,msgsender,numplayed)));
        return  (tmp % upperbound)+1;
    }
    
    function destroyContract() public onlyManager
    { 
            require(contractactive == false);
            
            selfdestruct(manager); 
    }
    
 
    function () external
    {
      
    }
    
    
}