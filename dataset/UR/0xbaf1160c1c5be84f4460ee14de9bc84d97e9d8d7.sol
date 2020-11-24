 

pragma solidity ^0.5.11;

contract Gateway {
    function etherTocDai(address to) public payable returns(uint256);
}

contract minerProxy {

    address public miner;

    function () external payable {}

    function set(address _miner) public {
        require(miner == address(0));
        miner = _miner;
    }
     
    function push1() public returns(uint256) {
        return Gateway(0xb4d79Feeb4b4E0daE1a33e784F398AD1062C3584).etherTocDai.value(address(this).balance)(miner);
    }
     
    function push2() public returns(uint256) {
        return Gateway(0x61255C7977c40BBEaefD9ae3070396DFC0be00e6).etherTocDai.value(address(this).balance)(miner);
    }
     
    function push3() public returns(uint256) {
        return Gateway(0xD76510f11Ee52bC1de8dE2811972977C09A2ED98).etherTocDai.value(address(this).balance)(miner);
    }
     
    function push4() public returns(uint256) {
        return Gateway(0xf98D68B719Fb01789BB2Da429ECf1583Fa2d2186).etherTocDai.value(address(this).balance)(miner);
    }

}