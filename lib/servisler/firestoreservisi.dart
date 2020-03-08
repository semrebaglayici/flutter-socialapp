import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socialapp/modeller/gonderi.dart';
import 'package:socialapp/modeller/kullanici.dart';

class FireStoreServisi {
  final Firestore _firestore = Firestore.instance;
  final DateTime timestamp = DateTime.now();

  Future<void> kullaniciOlustur({id, email, kullaniciAdi, fotoUrl = ""}) async {
    await _firestore.collection("kullanicilar").document(id).setData({
      "id": id,
      "username": kullaniciAdi,
      "photoUrl": fotoUrl,
      "email": email,
      "bio": "",
      "timestamp": timestamp
    });
  }

  Future<Kullanici> kullaniciGetir(id) async {
    DocumentSnapshot doc =
        await _firestore.collection("kullanicilar").document(id).get();

    if (doc.exists) {
      Kullanici kullanici = Kullanici.dokumandanUret(doc);
      return kullanici;
    }

    return null;
  }

  Future<int> takipciSayisi(kullaniciId) async {
    QuerySnapshot snapshot = await _firestore
        .collection("takipciler")
        .document(kullaniciId)
        .collection("kullanicininTakipcileri")
        .getDocuments();
    return snapshot.documents.length;
  }

  Future<int> takipEdileniSayisi(kullaniciId) async {
    QuerySnapshot snapshot = await _firestore
        .collection("takipedilenler")
        .document(kullaniciId)
        .collection("kullanicininTakipleri")
        .getDocuments();
    return snapshot.documents.length;
  }

  Future<void> gonderiOlustur(
      {gonderResimiUrl, aciklama, yayinlayanId, konum}) async {
    await _firestore
        .collection("gonderiler")
        .document(yayinlayanId)
        .collection("kullaniciGonderileri")
        .add({
      "gonderResimiUrl": gonderResimiUrl,
      "aciklama": aciklama,
      "yayinlayanId": yayinlayanId,
      "begeniSayisi": 0,
      "konum": konum,
    });
  }

  Future<List<Gonderi>> gonderileriGetir(kullaniciId) async {
    QuerySnapshot snapshot = await _firestore
        .collection("gonderiler")
        .document(kullaniciId)
        .collection("kullaniciGonderileri")
        .getDocuments();

    List<Gonderi> gonderiler =
        snapshot.documents.map((doc) => Gonderi.dokumandanUret(doc)).toList();
    return gonderiler;
  }

  Future<void> gonderiBegen({String aktifKullaniciId, Gonderi gonderi}) async {
    //Beğeni sayısını artır
    
    DocumentReference docRef = _firestore
        .collection("gonderiler")
        .document(gonderi.yayinlayanId)
        .collection("kullaniciGonderileri")
        .document(gonderi.id);

    DocumentSnapshot doc = await docRef.get();

    if (doc.exists) {
      Gonderi gonderi = Gonderi.dokumandanUret(doc);
      int yenibegeniSayisi = gonderi.begeniSayisi + 1;
      docRef.updateData({"begeniSayisi":yenibegeniSayisi});
      

      //begeniler koleksiyonuna ekle
      _firestore
        .collection("begeniler")
        .document(gonderi.id)
        .collection("gonderiBegenileri")
        .document(aktifKullaniciId)
        .setData({});

    }
  }


  Future<void> gonderiBegeniKaldir({String aktifKullaniciId, Gonderi gonderi}) async {
    //Beğeni sayısını azalt
    
    DocumentReference docRef = _firestore
        .collection("gonderiler")
        .document(gonderi.yayinlayanId)
        .collection("kullaniciGonderileri")
        .document(gonderi.id);

    DocumentSnapshot doc = await docRef.get();

    if (doc.exists) {
      Gonderi gonderi = Gonderi.dokumandanUret(doc);
      int yenibegeniSayisi = gonderi.begeniSayisi - 1;
      docRef.updateData({"begeniSayisi":yenibegeniSayisi});

      DocumentSnapshot docBegeni = await _firestore
        .collection("begeniler")
        .document(gonderi.id)
        .collection("gonderiBegenileri")
        .document(aktifKullaniciId).get();

      if(docBegeni.exists){
        //Önce böyle bir kayıt olduğundan emin olduk. Sonra sildik.
        docBegeni.reference.delete();
      }
        


    }
  }

  Future<bool> begeniVarmi({String aktifKullaniciId, Gonderi gonderi}) async {
    DocumentSnapshot doc = await _firestore
        .collection("begeniler")
        .document(gonderi.id)
        .collection("gonderiBegenileri")
        .document(aktifKullaniciId).get();

        if(doc.exists){
          //doc varsa beğeni var
          return true;
        }
        //Tek satırda da yazılabilir
        return false;
  }


  Stream<QuerySnapshot> yorumlariGetir(String gonderiId)  {
  
   return  _firestore
    .collection("yorumlar")
        .document(gonderiId)
        .collection("gonderiYorumlari")
        .orderBy('timestamp', descending: true)
        .snapshots();

  }


 void yorumEkle({String aktifKullaniciId, String gonderiId, String icerik}){
    
    _firestore
    .collection("yorumlar")
        .document(gonderiId)
        .collection("gonderiYorumlari")
        .add({
          "icerik":icerik,
          "yayinlayanId":aktifKullaniciId,
          "timestamp":timestamp,
        });

  }


  void kullaniciGuncelle({String kullaniciId, String kullaniciAdi, String fotoUrl = "", String hakkinda}){
    
    _firestore
    .collection("kullanicilar")
        .document(kullaniciId)
        .updateData({
          "username":kullaniciAdi,
          "photoUrl":fotoUrl,
          "bio":hakkinda,
        });

  }

  Future<List<Kullanici>> kullaniciAra(String kelime) async {

     QuerySnapshot snapshot = await _firestore
    .collection("kullanicilar")
    .where("username",isGreaterThanOrEqualTo: kelime )
    .getDocuments();

    
        List<Kullanici> kullanicilar =
        snapshot.documents.map((doc) => Kullanici.dokumandanUret(doc)).toList();
        return kullanicilar;

  }


}
