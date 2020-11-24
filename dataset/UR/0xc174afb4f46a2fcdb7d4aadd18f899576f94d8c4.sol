 

pragma solidity  ^0.4.24;
 

contract AllYours {


    address private _platformAddress = 0x14551DeA29FAe64D84ba5670F7311E71a15e83e2;

    uint private _totalEth = 1 ether;

    uint128 private _oneceEth = 0.1 ether;

    uint32 private _period = 1;

    address private _owner;



    constructor() public{

        _owner = msg.sender;

    }

    address[] private _allAddress;

    uint16 private _currentJoinPersonNumber;


    event drawCallback(address winnerAddress,uint period,uint balance,uint time );



    function getCurrentJoinPersonNumber() view public returns(uint24) {

        return _currentJoinPersonNumber;

    }



    function getPeriod() view public returns(uint32) {

        return _period;

    }

    function getCurrentBalance() view public returns(uint256) {

        return address(this).balance;

    }



    function draw() internal view returns (uint24) {

        bytes32 hash = keccak256(abi.encodePacked(block.number));

        uint256 random = 0;

        for(uint i=hash.length-8;i<hash.length;i++) {

            random += uint256(hash[i])*(10**(hash.length-i));

        }

        random += now;



        bytes memory hashAddress=toBytes(_allAddress[0]);

        for(uint j=0;j<8;j++) {

            random += uint(hashAddress[j])*(10**(8-j));

        }

        uint24 index = uint24(random % _allAddress.length);

        return index;



    }




    function kill() public payable {

        if (_owner == msg.sender) {

            _platformAddress.transfer(address(this).balance);

            selfdestruct(_owner);

        }

    }



    function() public payable {

        require(msg.value >= _oneceEth);


        uint len = msg.value/_oneceEth;

        for(uint i=0;i<len;i++) {

            _allAddress.push(msg.sender);

        }
        _currentJoinPersonNumber ++;


        if(address(this).balance >= _totalEth) {

            uint24 index = draw();

            address drawAddress = _allAddress[index];

            uint256 b = address(this).balance;

            uint256 pay = b*70/100;

            drawAddress.transfer(pay);

            _platformAddress.transfer(b*30/100);



            emit drawCallback(drawAddress,_period,pay,now);

            _period ++;

            clear();

        }

    }



    function clear() internal {

        _currentJoinPersonNumber = 0;

        delete _allAddress;

    }



    function toBytes(address x) internal pure returns (bytes b) {

        b = new bytes(20);

        for (uint i = 0; i < 20; i++)

            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));

    }



}