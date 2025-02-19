// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface CallProxy{
    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;

    function context() external view returns (address from, uint256 fromChainID, uint256 nonce);
    
    function executor() external view returns (address executor);
}

  

contract AnycallFallback{


    // The FTM testnet anycall contract
    address public anycallcontract;
    // address public anycallExecutor;
    

    address public owneraddress;

    // Our Destination contract on Rinkeby testnet
    address public receivercontract;
    


    address public verifiedcaller;

    uint public destchain;
    event NewMsg(string msg);

    receive() external payable {}

    fallback() external payable {}

    constructor(address _anycallcontract,uint _destchain){
        anycallcontract=_anycallcontract;
        owneraddress=msg.sender;
        destchain=_destchain;
        // anycallExecutor=CallProxy(anycallcontract).executor();
        
    }
    
    modifier onlyowner() {
        require(msg.sender == owneraddress, "only owner can call this method");
        _;
    }
    function changedestinationcontract(address _destcontract) onlyowner external {
        receivercontract=_destcontract;
    }

    function changeverifiedcaller(address _contractcaller) onlyowner external {
        verifiedcaller=_contractcaller;
    }

    function step1_initiateAnyCallSimple_srcfee(string calldata _msg) payable external {
        emit NewMsg(_msg);
        if (msg.sender == owneraddress){
        CallProxy(anycallcontract).anyCall{value: msg.value}(
            receivercontract,

            // sending the encoded bytes of the string msg and decode on the destination chain
            abi.encode(_msg),

            destchain,

            // Using 0 flag to pay fee on the source chain
            4,
            ""
            );
            
        }

    }


    event LogFallbackMsg(string _message);
    // anyExecute has to be role controlled by onlyMPC so it's only called by MPC

   function anyExecute(bytes memory _data) external returns (bool success, bytes memory result){
        (string memory _msg) = abi.decode(_data, (string));  

        emit NewMsg("fail on purpose here to fallback");



        //demonstrate fallback
        success=false;
        result='';

   }



    function anyFallback(bytes calldata data)
        external
        returns (bool success, bytes memory result)
    {

        (
            string memory message

        ) = abi.decode(data, (string));

        emit LogFallbackMsg(message);
        return (true, ""); 

    }
}