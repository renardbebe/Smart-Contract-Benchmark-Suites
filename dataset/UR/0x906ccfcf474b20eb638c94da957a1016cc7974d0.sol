 

contract BitSTDView{
    function symbol()constant  public returns(string) {}
    function migration(address add) public{}
    function transfer(address _to, uint256 _value) public {}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
}
contract airDrop{
     
    function airDrop_(address contractaddress,address[] dsts,uint256 value) public {

        uint count= dsts.length;
        require(value>0);
        BitSTDView View= BitSTDView(contractaddress);
        for(uint i = 0; i < count; i++){
           View.transfer(dsts[i],value);
        }
    }
     
    function airDropValues(address contractaddress,address[] dsts,uint256[] values) public {

        uint count= dsts.length;
        BitSTDView View= BitSTDView(contractaddress);
        for(uint i = 0; i < count; i++){
           View.transfer(dsts[i],values[i]);
        }
    }
     
    function dataMigration(address contractaddress,address[] dsts)public{
        uint count= dsts.length;
        BitSTDView View= BitSTDView(contractaddress);
        for(uint i = 0; i < count; i++){
           View.migration(dsts[i]);
        }
    }
     
    function transferFrom(address contractaddress,address _from, address[] dsts, uint256 value) public returns (bool success) {
        uint count= dsts.length;
        BitSTDView View= BitSTDView(contractaddress);
        for(uint i = 0; i < count; i++){
           View.transferFrom(_from,dsts[i],value);
        }
    }

}