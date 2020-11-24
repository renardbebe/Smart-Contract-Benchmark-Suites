 

pragma solidity ^0.5.0;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
        }
    }



 

contract p3Dank  {
    using SafeMath for uint;
    uint256 public _totalhouses;  
    uint256 public blocksbeforeaction = 1680; 
    uint256 public nextFormation; 
    mapping(address => uint256)public _playerhouses;  
    mapping(address => uint256)public lastmove; 
    mapping(address => uint256) buyblock; 
    address payable happydev = 0xDC6dfe8040fc162Ab318De99c63Ec2cd0e203010;  

   struct house {  
       address owner;  
       uint8 rpstype;  
   }

    mapping(uint256 => house)public formation; 

     

    modifier ishuman() { 
        address _addr = msg.sender;
        uint256 _codeLength;
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    modifier canmove() {
          address sender = msg.sender;
          require(_playerhouses[sender] > 0);
          require(canimoveyet());
          _;
    }

     

    event sell (address seller, uint256 plantsize, uint256 cashout);
    event battle(address attacker, uint8 ktype, address defender);
    event win (uint256 position, uint256 sizesold, uint256 amountsent);  
    event buyin (address buyer, uint256 blockbuy);  

    function () external payable{}

    function buyhouses() ishuman() public payable {  
        uint256 value = msg.value;
        if(value == 200 finney){ 
            address sender = msg.sender;
            if(_playerhouses[sender] == 0 ){  
                _playerhouses[sender] = 3;  
                uint256 next = nextFormation;
                formation[next++] = house(sender, 1); 
                formation[next++] = house(sender, 2); 
                formation[next++] = house(sender, 3);
                nextFormation = next;
                lastmove[sender] = block.number;  
                buyblock[sender] = block.number;  
                _totalhouses += 3; 
                happydev.transfer(2 finney);
                totaldivpts += 3000;
                emit buyin(sender, buyblock[sender]);
                } } }

    bool gameon;

    function startgame() public payable {
        uint256 value = msg.value;
        require(value == 200 finney); 
        require (gameon == false);
        address sender = msg.sender;
        _playerhouses[sender] = _playerhouses[sender]+3; 
        formation[nextFormation] = house(sender, 1); 
        nextFormation++;
        formation[nextFormation] = house(sender, 2); 
        nextFormation++;
        formation[nextFormation] = house(sender, 3);
        nextFormation++;
        lastmove[sender] = block.number;  
        buyblock[sender] = block.number;  
        _totalhouses = _totalhouses+3; 
        happydev.transfer(2 finney);
        lastupdateblock = block.number;
        gameon = true;
        totaldivpts += 3000;
        emit buyin(sender, buyblock[sender]);
    }

     
    uint256 lastupdateblock;
    uint256 totaldivpts;

    function updateglobal() internal {                       
        totaldivpts = gametotaldivs();
        lastupdateblock = block.number; 
        lastmove[msg.sender] = block.number;  
    }

    function rekt(uint8 typeToKill) internal {
        updateglobal();
        uint256 attacked = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin))) % nextFormation;
        uint256 _rpstype = formation[attacked].rpstype;
        address killed = formation[attacked].owner; 
        address payable sender = msg.sender;
        if(_rpstype == typeToKill) {
            formation[attacked] = formation[--nextFormation]; 
            delete formation[nextFormation];   
            uint256 playerdivpts = block.number.sub(buyblock[killed]).add(1000); 
            uint256 robbed = (address(this).balance).mul(playerdivpts).div(totaldivpts).div(2);  
            totaldivpts = totaldivpts.sub(playerdivpts);  
            _totalhouses--; 
            _playerhouses[killed]--; 
            sender.transfer(robbed); 
            emit win(attacked, playerdivpts, robbed);  
        }
        emit battle(sender, typeToKill, killed);
        } 
  
        

    function rockattack() canmove() public {  
        rekt(3);
        }

    function sisattack() canmove() public {  
        rekt(1);
        }

    function papattack() canmove() public { 
        rekt(2);
        }

    function sellhouse (uint256 selling) canmove() public { 
        address payable sender = msg.sender;
        address beingsold = formation[selling].owner;
        if (beingsold == sender){  
            updateglobal();
            uint256 next = --nextFormation;
            formation[selling] = formation[next];
            delete formation[next];
            _totalhouses--; 
            _playerhouses[sender]--; 
            uint256 maxbuyblock = 69420;
            uint256 playerdivpts = block.number.sub(buyblock[sender]).add(1000);
            uint256 sold;
            if (playerdivpts >= maxbuyblock) {
                sold = (address(this).balance).mul(maxbuyblock * 4).div(totaldivpts);
                }
            else {
                uint256 payoutmultiplier = playerdivpts.mul(playerdivpts).mul(10000).div(1953640000).add(10000);
                sold = (address(this).balance).mul(playerdivpts).mul(payoutmultiplier).div(totaldivpts).div(10000);
            }
            totaldivpts = totaldivpts.sub(playerdivpts);  
            sender.transfer(sold); 
            emit sell(sender, playerdivpts, sold);
            } }         


     
    function singleplantdivs ()public view returns(uint256){  
        return(block.number.sub(buyblock[msg.sender]).add(1000));
    }
    function howmanyplants ()public view returns(uint256){  
        return(_playerhouses[msg.sender]);
    }
    function whatblockmove ()public view returns(uint256){   
        return(lastmove[msg.sender]).add(blocksbeforeaction);
    }
    function canimoveyet ()public view returns(bool){  
        if (blocksbeforeaction <= (block.number).sub(lastmove[msg.sender])) return true;
    }
    function howmucheth ()public view returns(uint256){ 
        return address(this).balance;
    }
    function gametotaldivs ()public view returns(uint256){ 
        return (block.number).sub(lastupdateblock).mul(_totalhouses).add(totaldivpts);
    }
    function singleplantpayout ()public view returns(uint256){
        uint256 playerdivpts = block.number.sub(buyblock[msg.sender]).add(1000);
        uint256 maxbuyblock = 69420;
        if (playerdivpts >= maxbuyblock) {
            return (address(this).balance).mul(maxbuyblock * 4).div(totaldivpts);
        }
        else {
            uint256 payoutmultiplier = playerdivpts.mul(playerdivpts).mul(10000).div(1953640000).add(10000);
            return (address(this).balance).mul(playerdivpts).mul(payoutmultiplier).div(totaldivpts).div(10000);
        }
    }

 
}