<template>
  <div>
    <div ref="scroll" flex class="scroll-wrapper" style="height: calc(100%-1.1rem);">
      <div flex-box="1" flex="dir:top cross: center">
        <van-field v-model="contractAddress" center type="text" :placeholder="$t('input_contract_addr')" style="margin-top: 0.3rem;" />
        <button :disabled="!registerEnable" class="jcc-moac-alarm-button jcc-moac-alarm-register-button" style="width: 100%; margin-top: 0.4rem;" @click="goRegister">
          {{ $t("confirm_register") }}
        </button>
      </div>
    </div>
  </div>
</template>
<script>
import { moacWallet } from "jcc_wallet";
import tpInfo from "@/js/tp";
import AlarmContractInstance from "@/js/contract";
import * as transaction from "@/js/transaction";
import { Toast } from "vant";
import scrollIntoView from "@/mixins/scrollIntoView";
export default {
  mixins: [scrollIntoView],
  data() {
    return {
      contractAddress: "",
      registerEnable: false
    };
  },
  computed: {
    inputAddress() {
      return this.contractAddress;
    }
  },
  watch: {
    inputAddress(newVal) {
      const newMoacAddress = newVal.trim();
      if (!moacWallet.isValidAddress(newMoacAddress)) {
        this.registerEnable = false;
        return;
      }
      this.validAddress(newMoacAddress);
    }
  },
  beforeDestroy() {
    AlarmContractInstance.destroy();
  },
  methods: {
    async validAddress(address) {
      try {
        const node = await tpInfo.getNode();
        const instance = AlarmContractInstance.init(node);
        const chain3 = instance.moac.getChain3();
        const code = chain3.mc.getCode(address);
        if (code === "0x") {
          console.log("this is address");
          this.registerEnable = false;
        } else {
          console.log("this is contract address");
          this.registerEnable = true;
        }
      } catch (error) {
        console.log("valid address error", error);
        this.registerEnable = false;
      }
    },
    async goRegister() {
      try {
        const node = await tpInfo.getNode();
        const instance = AlarmContractInstance.init(node);
        const hash = await instance.contractRegister(this.contractAddress);
        console.log("contract register hash: ", hash);
        Toast.loading({
          duration: 0,
          forbidClick: true,
          loadingType: "spinner",
          message: this.$t("message.register_loading")
        });
        setTimeout(async () => {
          const res = await transaction.requestReceipt(hash);

          if (res) {
            if (transaction.isSuccessful(res)) {
              Toast.success(this.$t("message.register_succeed"));
            } else {
              Toast.fail(this.$t("message.register_failed"));
            }
          } else {
            Toast.fail(this.$t("message.request_receipt_failed"));
          }
        }, 20000);
      } catch (error) {
        console.log("contract register error: ", error);
        Toast.fail(error.message);
      }
    }
  }
};
</script>
<style lang="scss" scoped></style>
