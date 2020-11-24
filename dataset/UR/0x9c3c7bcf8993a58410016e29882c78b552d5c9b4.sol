 

pragma solidity ^0.5.12;

 
contract NEST_3_OrePoolLogic {
    using address_make_payable for address;
    using SafeMath for uint256;
    uint256 blockAttenuation = 2400000;                          
    uint256 attenuationTop = 90;                                 
    uint256 attenuationBottom = 100;                             
    mapping(uint256 => mapping(address => uint256)) blockEth;    
    mapping(uint256 => uint256) blockTokenNum;                   
    mapping(uint256 => uint256) blockMining;                     
    uint256 latestMining;                                        
    NEST_2_Mapping mappingContract;                              
    NEST_3_MiningSave miningSave;                                
    address abonusAddress;                                       
    address offerFactoryAddress;                                 
    mapping(uint256 => uint256) blockAmountList;                 
    uint256 latestBlock;                                         

     
    event oreDrawingLog(uint256 nowBlock, uint256 frontBlock, uint256 blockAmount, uint256 miningEth, address tokenAddress);
     
    event miningLog(uint256 blockNum, address tokenAddress, uint256 miningEthAll, uint256 miningEthSelf, uint256 tokenNum);

     
    constructor(address map) public {
        mappingContract = NEST_2_Mapping(address(map));                  
        miningSave = NEST_3_MiningSave(mappingContract.checkAddress("miningSave"));
        abonusAddress = address(mappingContract.checkAddress("abonus"));
        offerFactoryAddress = address(mappingContract.checkAddress("offerFactory"));
        latestBlock = block.number.sub(388888);
        latestMining = block.number;
        blockAmountList[block.number.sub(2788888)] = 400 ether;
        blockAmountList[block.number.sub(388888)] = blockAmountList[block.number.sub(2788888)].mul(attenuationTop).div(attenuationBottom);
    }
    
     
    function changeMapping(address map) public onlyOwner {
        mappingContract = NEST_2_Mapping(address(map));                 
        miningSave = NEST_3_MiningSave(mappingContract.checkAddress("miningSave"));
        abonusAddress = address(mappingContract.checkAddress("abonus"));
        offerFactoryAddress = address(mappingContract.checkAddress("offerFactory"));
    }
    
     
    function oreDrawing(address token) public payable {
        require(address(msg.sender) == offerFactoryAddress);
        uint256 frontBlock = latestMining;
        changeBlockAmountList();
        if (blockEth[block.number][token] == 0) {
            blockTokenNum[block.number] = blockTokenNum[block.number].add(1);
        }
        blockEth[block.number][token] = blockEth[block.number][token].add(msg.value);
        repayEth(msg.value);
        emit oreDrawingLog(block.number, frontBlock,blockAmountList[latestBlock],msg.value,token);
    }
    
     
    function mining(uint256 amount, uint256 blockNum, address target, address token) public returns(uint256) {
        require(address(msg.sender) == offerFactoryAddress);
        uint256 miningAmount = amount.mul(blockMining[blockNum]).div(blockEth[blockNum][token].mul(blockTokenNum[blockNum]));
        uint256 realAmount = miningSave.turnOut(miningAmount, target);
        emit miningLog(blockNum, token,blockEth[blockNum][token],amount,blockTokenNum[blockNum]);
        return realAmount;
    }
    
    function changeBlockAmountList() private {
        uint256 subBlock = block.number.sub(latestBlock);
        if (subBlock >= blockAttenuation) {
            uint256 subBlockTimes = subBlock.div(blockAttenuation);
            for (uint256 i = 1; i < subBlockTimes.add(1); i++) {
                uint256 newBlockAmount = blockAmountList[latestBlock].mul(attenuationTop).div(attenuationBottom);
                latestBlock = latestBlock.add(blockAttenuation);
                if (latestMining < latestBlock) {
                    blockMining[block.number] = blockMining[block.number].add((blockAmountList[latestBlock.sub(blockAttenuation)]).mul(latestBlock.sub(latestMining).sub(1)));
                    latestMining = latestBlock.sub(1);
                }
                blockAmountList[latestBlock] = newBlockAmount;
            }
        }
        blockMining[block.number] = blockMining[block.number].add(blockAmountList[latestBlock].mul(block.number.sub(latestMining)));
        latestMining = block.number;
    }
    
    function repayEth(uint256 asset) private {
        address payable addr = abonusAddress.make_payable();
        addr.transfer(asset);
    }

     
    function checkBlockAttenuation() public view returns(uint256) {
        return blockAttenuation;
    }

     
    function checkAttenuation() public view returns(uint256 top, uint256 bottom) {
        return (attenuationTop, attenuationBottom);
    }

     
    function checkBlockEth(uint256 blockNum, address token) public view returns(uint256) {
        return blockEth[blockNum][token];
    }

     
    function checkBlockTokenNum(uint256 blockNum) public view returns(uint256) {
        return blockTokenNum[blockNum];
    }

     
    function checkBlockMining(uint256 blockNum) public view returns(uint256) {
        return blockMining[blockNum];
    }

     
    function checkLatestMining() public view returns(uint256) {
        return latestMining;
    }

     
    function checkBlockAmountList(uint256 blockNum) public view returns(uint256) {
        return blockAmountList[blockNum];
    }

     
    function checkBlockAmountListLatest() public view returns(uint256) {
        return blockAmountList[latestBlock];
    }

     
    function checkLatestBlock() public view returns(uint256) {
        return latestBlock;
    }

     
    function checkBlockRealAmount(uint256 amount, uint256 blockNum, address token) public view returns(uint256) {
        return amount.mul(blockMining[blockNum]).div(blockEth[blockNum][token].mul(blockTokenNum[blockNum]));
    }

    function changeBlockAttenuation(uint256 blockNum) public onlyOwner {
        require(blockNum > 0);
        blockAttenuation = blockNum;
    }
    
    function changeAttenuation(uint256 top, uint256 bottom) public onlyOwner {
        require(top > 0);
        require(bottom > 0);
        attenuationTop = top;
        attenuationBottom = bottom;
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }
}

contract NEST_3_MiningSave {
    function turnOut(uint256 amount, address target) public returns(uint256);
    function checkBalance() public view returns(uint256);
}

contract NEST_2_Mapping {
	function checkAddress(string memory name) public view returns (address contractAddress);
	function checkOwners(address man) public view returns (bool);
}

contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address who ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint256 value) external;
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b > 0);  
    uint256 c = _a / _b;
    assert(_a == _b * c + _a % _b);  
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}